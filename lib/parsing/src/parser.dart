import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'package:star/errors/errors.dart';
import 'package:star/lexing/lexing.dart';
import 'package:star/ast/ast.dart';

import 'result.dart';

typedef Typevars = List<Typevar>;

Program parse(Tokens tokens) => switch(tokens) {
	[Token(k: K.lsep), ...var rest] => parse(rest),
	[Token(k: K.use, span: var _1), TLitsym(name: "script", span: var _2), ...var rest] => parseScript(_1, _2, rest),
	_ => parseModular(tokens)
};

Program parseScript(Span _1, Span _2, Tokens input) {
	throw "NYI";
}

Program parseModular(Tokens input) {
	var tokens = input.copy();
	var expectSep = false;
	var lastWasError = false;

	final errors = <StarError>[];
	final decls = <Decl>[];
	final badTokens = <Token>[];

	while(tokens.isNotEmpty) {
		final oldTokens = tokens.copy(); // bad for perf?

		if(expectSep) {
			final first = tokens.removeAt(0);

			if(!first.isAnySep) {
				errors.add(StarError.unexpectedTokenWantedSep(first));
				badTokens.add(first);
			}
		}

		switch(nextDecl([], tokens)) {
			case Success(made: var decl, :var rest):
				decls.add(decl);
				tokens = rest;
				if(!expectSep) expectSep = true;
				if(lastWasError) lastWasError = false;
			
			case Failure(:var begin, end: null) || Fatal(:var begin, end: null):
				final first = begin.first;

				if(!badTokens.contains(first) && !(lastWasError && first.isAnySep)) {
					errors.add(StarError.unexpectedToken(first, null));
					badTokens.add(first);
				}

				if(tokens.isNotEmpty) tokens.removeAt(0);
				loop: while(true) switch(tokens) {
					case [] || [Token(k: K.lsep)]: break loop;
					default: tokens.removeAt(0);
				}

				expectSep = false;
				lastWasError = true;

			case Failure(:var begin, :var end!) || Fatal(:var begin, :var end!):
				final first = begin.first;
				final last = end.isNotEmpty? end.first : begin.last;
				
				if(!badTokens.contains(last)) {
					errors.add(StarError.unexpectedToken(first, last));
					badTokens.add(last);
				}

				loop: while(true) switch(tokens) {
					case [] || [Token(k: K.lsep)]: break loop;
					default: tokens.removeAt(0);
				}

				expectSep = false;
				lastWasError = true;
			
			case EndOfInput(:var begin):
				final realBegin = (
					begin.isNotEmpty? begin:
					tokens.isNotEmpty? tokens:
					oldTokens
				);

				final first = realBegin.first;
				final last = realBegin.last;

				if(!badTokens.contains(first)) {
					errors.add(StarError.unexpectedEOF(first, last));
					badTokens.add(first);
				}

				tokens = [];
			
			case FatalError(:var error):
				errors.add(error);

				loop: while(true) switch(tokens) {
					case [] || [Token(k: K.lsep)]: break loop;
					default: tokens.removeAt(0);
				}

				expectSep = false;
				lastWasError = true;
		}
	}

	return PModular(decls, errors: errors);
}


/* DECLS */

Result<Delims<List<Decl>>> nextDeclBody(Tokens tokens) {
	switch(tokens) {
		case [Token(k: K.lbrace, span: var begin), Token(k: K.rbrace, span: var end), ...var rest]:
			return Success((begin: begin, of: [], end: end), rest);
		case [Token(k: K.lbrace, span: var begin), ...var rest]:
			final decls = <Decl>[];
			while(true) switch(nextDecl([], rest)) {
				case Success(made: var decl, rest: var rest2):
					decls.add(decl);

					switch(rest2) {
						case [Token(k: K.rbrace, span: var end), ...var rest3]: return Success((begin: begin, of: decls, end: end), rest3);
						case []: return EndOfInput(tokens);
						case [var t, ...var rest3] when t.isAnySep: rest = rest3;
						default: return Fatal(tokens, rest2);
					}
				
				case var err: return err.cast();
			}
		default: return Failure(tokens, null);
	}
}

Result<Decl> nextDecl(Typevars typevars, Tokens tokens) => switch(tokens) {
	[Token(k: K.type, span: var _1), ...var rest] => switch(parseTypevar(_1, rest)) {
		Success(made: var tvar, rest: [var s, ...var rest2]) when s.isAnySep => nextDecl(typevars..add(tvar), rest2),
		Success(made: _, rest: var rest2) => Fatal(tokens, rest2),
		var err => err.cast()
	},
	[Token(k: K.use, span: var _1), TLitsym(span: var _2, :var name), var s, ...var rest] when s.isAnySep =>
		parseUsePragma(typevars, _1, _2, name, rest),
	[Token(k: K.use, span: var _1), ...var rest] => parseUseDecl(typevars, _1, rest).fatalIfBad(tokens),
	[Token(k: K.alias, span: var _1), ...var rest] => parseAliasDecl(typevars, _1, rest).fatalIfBad(tokens),
	[Token(k: K.module, span: var _1), ...var rest] => parseModuleDecl(typevars, _1, rest).fatalIfBad(tokens),
	[Token(k: K.class_, span: var _1), ...var rest] => parseClassDecl(typevars, _1, rest).fatalIfBad(tokens),
	[Token(k: K.protocol, span: var _1), ...var rest] => parseProtocolDecl(typevars, _1, rest).fatalIfBad(tokens),
	[Token(k: K.category, span: var _1), ...var rest] => parseCategoryDecl(typevars, _1, rest).fatalIfBad(tokens),
	[Token(k: K.kind, span: var _1), ...var rest] => parseKindDecl(typevars, _1, rest).fatalIfBad(tokens),
	[Token(k: K.my, span: var _1), ...var rest] => typevars.isEmpty
		? parseMemberDecl(_1, rest).fatalIfBad(tokens)
		: FatalError(StarError.noGenericMember(_1)),
	[Token(k: K.has, span: var _1), ...var rest] => typevars.isEmpty
		? parseCaseDecl(_1, rest).fatalIfBad(tokens)
		: FatalError(StarError.noGenericCase(_1)),
	[Token(k: K.init, span: var _1), ...var rest] => parseInitDecl(typevars, _1, rest).fatalIfBad(tokens),
	[Token(k: K.on, span: var _1), ...var rest] => parseMethodDecl(typevars, _1, rest).fatalIfBad(tokens),
	[Token(k: K.operator, span: var _1), ...var rest] => parseOperatorDecl(typevars, _1, rest).fatalIfBad(tokens),
	[Token(k: K.deinit, span: var _1), ...var rest] => typevars.isEmpty
		? parseDeinitDecl(_1, rest).fatalIfBad(tokens)
		: FatalError(StarError.noGenericDeinit(_1)),
	[_, ..._] => Fatal(tokens, null),
	[] => EndOfInput(tokens)
};


/* TYPEVARS */

Result<Typevar> parseTypevar(Span _1, Tokens tokens) {
	switch(parseTypeDeclName(tokens)) {
		case Success(made: (var name, var params), :var rest):
			List<Type>? parents; switch(parseTypeParents(rest)) {
				case Success(:var made, rest: var rest2):
					rest = rest2;
					parents = made.$2;
				case Failure(): parents = null;
				case var err: return err.cast();
			}

			final attrs = TypevarAttrs();

			loop: while(true) switch(rest) {
				case [Token(k: K.is_, span: var _2), Token(k: K.native, span: var _3), ...var rest2]:
					throw "nyi";
				case [Token(k: K.is_, span: var _2), Token(k: K.flags, span: var _3), ...var rest2]:
					attrs.isFlags = Span.range(_2, _3);
					rest = rest2;
				case [Token(k: K.is_, span: var _2), Token(k: K.strong, span: var _3), ...var rest2]:
					attrs.isStrong = Span.range(_2, _3);
					rest = rest2;
				case [Token(k: K.is_, span: var _2), Token(k: K.uncounted, span: var _3), ...var rest2]:
					attrs.isUncounted = Span.range(_2, _3);
					rest = rest2;
				
				default: break loop;
			}

			(Span, TypevarRule)? rule; if(rest case [Token(k: K.if_, span: var _2), ...var rest2]) {
				switch(parseTypevarRule(rest2)) {
					case Success(:var made, rest: var rest3):
						rule = (_2, made);
						rest = rest3;
					case var err: return err.cast();
				}
			} else {
				rule = null;
			}

			Body? body; switch(nextDeclBody(rest)) {
				case Success(:var made, rest: var rest2):
					body = made;
					rest = rest2;
				case Failure(): body = null;
				case var err: err.cast();
			};

			return Success(
				Typevar(_1, attrs,
					name: name,
					params: params,
					parents: parents,
					rule: rule,
					body: body
				),
				rest
			);
		
		case var err: return err.fatalIfBad(tokens).cast();
	}
}

Result<TypevarRule> parseTypevarRule(Tokens tokens) => throw "";

Result<TypevarRule> parseTypevarRuleCond(TypevarRule left, Tokens tokens) => throw "";

Result<TypevarRule> parseTypevarRuleTerm(Tokens tokens) => throw "";


/* IMPORTS */

Result<Use> parseUsePragma(Typevars typevars, Span _1, Span _2, String sym, Tokens tokens) {
	return Success(Use(_1, UseKind.pragma((name: sym, span: _2)), typevars: typevars), tokens);
}

Result<Use> parseUseDecl(Typevars typevars, Span _1, Tokens tokens) {
	switch(parseUseTree(tokens)) {
		case Success(made: var spec, :var rest):
			UseFrom? from = null; switch(rest) {
				case [TLabel(span: var _2, name: "from"), TStr(span: var _3, :var segs), ...var rest2]: switch(parseStrSegs(segs)) {
					case Success(made: [Left(v: var path)], rest: var rest3):
						rest = rest3;
						from = UseFrom.file(_2, (_3, path));
					case Success(): return Fatal(tokens, rest2); // TODO: custom error message
					case var err: return err.fatalIfBad(tokens).cast();
				}
				case [TLabel(span: var _2, name: "from"), ...var rest2]: switch(parseType(rest2)) {
					case Success(made: var type, rest: var rest3):
						rest = rest3;
						from = UFType(_2, type);
					case var err: return err.fatalIfBad(tokens).cast();
				}
			}

			if(rest case [TLabel(span: var _2, name: "as"), ...var rest2]) {
				return switch(parseUseTree(rest2)) {
					Success(made: var tree, rest: var rest3) => Success(Use(_1, UseKind.import(spec, from, (_2, tree)), typevars: typevars), rest3),
					var err => err.fatalIfBad(tokens).cast()
				};
			} else {
				return Success(Use(_1, UseKind.import(spec, from, null), typevars: typevars), rest);
			}

		case var err: return err.fatalIfBad(tokens).cast();
	}
}

Result<UseTree> parseUseTree(Tokens tokens) {
	switch(tokens) {
		case [Token(k: K.hashLBracket), ...var rest]:
			final types = <Type>[];

			while(true) switch(parseType(rest)) {
				case Success(made: var type, rest: var rest2):
					types.add(type);

					switch(rest2) {
						case [Token(k: K.rbracket), ...var rest3]: return Success(UTTypes(types), rest3);
						case []: return EndOfInput(tokens);
						case [var t] when t.isAnySep: return EndOfInput(tokens);
						case [var t, ...var rest3] when t.isAnySep: rest = rest3;
						default: return Fatal(tokens, rest2);
					}
				
				case var err: return err.cast();
			}
		
		case [Token(k: K.hashLParen), ...var rest]:
			final pairs = <(Type, Span, UseTree)>[];

			while(true) switch(parseType(rest)) {
				case Success(made: var type, rest: var rest2): switch(rest2) {
					case [Token(k: K.eqGt, span: var _1), ...var rest3]: switch(parseUseTree(rest3)) {
						case Success(made: var tree, rest: var rest4):
							pairs.add((type, _1, tree));

							switch(rest4) {
								case [Token(k: K.rparen), ...var rest5]: return Success(UTMap(pairs), rest5);
								case []: return EndOfInput(tokens);
								case [var t] when t.isAnySep: return EndOfInput(tokens);
								case [var t, ...var rest5] when t.isAnySep: rest = rest5;
								default: return Fatal(tokens, rest4);
							}
						
						case var err: return err.cast();
					}
					
					return Fatal(tokens, rest2);
				}

				case var err: return err.cast();
			}
		
		default:
			return switch(parseType(tokens)) {
				Success(made: var type, :var rest) => Success(UTType(type), rest),
				var err => err.cast()
			};
	}
}


/* TYPE DECLS */

Result<Alias> parseAliasDecl(Typevars typevars, Span _1, Tokens tokens) {
	throw "";
}

Result<Module> parseModuleDecl(Typevars typevars, Span _1, Tokens tokens) {
	switch(parseTypeDeclName(tokens)) {
		case Success(made: (var name, var params), :var rest):
			List<Type>? parents; switch(parseTypeParents(rest)) {
				case Success(:var made, rest: var rest2):
					rest = rest2;
					parents = made.$2;
				case Failure(): parents = null;
				case var err: return err.cast();
			}

			final attrs = ModuleAttrs();

			loop: while(true) switch(rest) {
				case [Token(k: K.is_, span: var _2), Token(k: K.hidden, span: var _3), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.sealed, span: var _3), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isSealed = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isSealed = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.main, span: var _3), ...var rest2]:
					attrs.isMain = Span.range(_2, _3);
					rest = rest2;
				case [Token(k: K.is_, span: var _2), Token(k: K.friend, span: var _3), ...var rest2]:
					switch(parseTypeSpec(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isFriend = (Span.range(_2, _3), made);
							rest = rest3;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.native, span: var _3), TLitsym(span: var _4, :var name), ...var rest2]:
					attrs.isNative = (Span.range(_2, _3), (span: _4, name: name));
					rest = rest2;
				
				default: break loop;
			}

			return switch(nextDeclBody(rest)) {
				Success(made: var body, rest: var rest2) => Success(
					Module(_1, attrs,
						typevars: typevars,
						name: name,
						params: params,
						parents: parents,
						body: body
					),
					rest2
				),
				var err => err.cast()
			};
		
		case var err: return err.fatalIfBad(tokens).cast();
	}
}

Result<Class> parseClassDecl(Typevars typevars, Span _1, Tokens tokens) {
	switch(parseTypeDeclName(tokens)) {
		case Success(made: (var name, var params), :var rest):
			List<Type>? parents; switch(parseTypeParents(rest)) {
				case Success(:var made, rest: var rest2):
					rest = rest2;
					parents = made.$2;
				case Failure(): parents = null;
				case var err: return err.cast();
			}

			final attrs = ClassAttrs();

			loop: while(true) switch(rest) {
				case [Token(k: K.is_, span: var _2), Token(k: K.hidden, span: var _3), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.sealed, span: var _3), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isSealed = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isSealed = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.friend, span: var _3), ...var rest2]:
					switch(parseTypeSpec(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isFriend = (Span.range(_2, _3), made);
							rest = rest3;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.native, span: var _3), TLitsym(span: var _4, :var name), ...var rest2]:
					//attrs.isNative = (Span.range(_2, _3), (span: _4, name: name));
					//rest = rest2;
					throw "nyi";
				case [Token(k: K.is_, span: var _2), Token(k: K.strong, span: var _3), ...var rest2]:
					attrs.isStrong = Span.range(_2, _3);
					rest = rest2;
				case [Token(k: K.is_, span: var _2), Token(k: K.uncounted, span: var _3), ...var rest2]:
					attrs.isUncounted = Span.range(_2, _3);
					rest = rest2;
				
				default: break loop;
			}

			return switch(nextDeclBody(rest)) {
				Success(made: var body, rest: var rest2) => Success(
					Class(_1, attrs,
						typevars: typevars,
						name: name,
						params: params,
						parents: parents,
						body: body
					),
					rest2
				),
				var err => err.cast()
			};
		
		case var err: return err.fatalIfBad(tokens).cast();
	}
}

Result<Protocol> parseProtocolDecl(Typevars typevars, Span _1, Tokens tokens) {
	switch(parseTypeDeclName(tokens)) {
		case Success(made: (var name, var params), :var rest):
			List<Type>? parents; switch(parseTypeParents(rest)) {
				case Success(:var made, rest: var rest2):
					rest = rest2;
					parents = made.$2;
				case Failure(): parents = null;
				case var err: return err.cast();
			}

			final attrs = ProtocolAttrs();

			loop: while(true) switch(rest) {
				case [Token(k: K.is_, span: var _2), Token(k: K.hidden, span: var _3), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.sealed, span: var _3), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isSealed = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isSealed = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.friend, span: var _3), ...var rest2]:
					switch(parseTypeSpec(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isFriend = (Span.range(_2, _3), made);
							rest = rest3;
						case var err: return err.cast();
					}
				
				default: break loop;
			}

			return switch(nextDeclBody(rest)) {
				Success(made: var body, rest: var rest2) => Success(
					Protocol(_1, attrs,
						typevars: typevars,
						name: name,
						params: params,
						parents: parents,
						body: body
					),
					rest2
				),
				var err => err.cast()
			};
		
		case var err: return err.fatalIfBad(tokens).cast();
	}
}

Result<Category> parseCategoryDecl(Typevars typevars, Span _1, Tokens tokens) {
	throw "";
}

Result<Kind> parseKindDecl(Typevars typevars, Span _1, Tokens tokens) {
	switch(parseTypeDeclName(tokens)) {
		case Success(made: (var name, var params), :var rest):
			Type? repr; switch(parseTypeAnno(tokens)) {
				case Success(:var made, rest: var rest2):
					rest = rest2;
					repr = made;
				case Failure(): repr = null;
				case var err: return err.cast();
			}

			List<Type>? parents; switch(parseTypeParents(rest)) {
				case Success(:var made, rest: var rest2):
					rest = rest2;
					parents = made.$2;
				case Failure(): parents = null;
				case var err: return err.cast();
			}

			final attrs = KindAttrs();

			loop: while(true) switch(rest) {
				case [Token(k: K.is_, span: var _2), Token(k: K.hidden, span: var _3), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.sealed, span: var _3), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isSealed = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isSealed = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.friend, span: var _3), ...var rest2]:
					switch(parseTypeSpec(rest2)) {
						case Success(:var made, rest: var rest3):
							attrs.isFriend = (Span.range(_2, _3), made);
							rest = rest3;
						case var err: return err.cast();
					}
				case [Token(k: K.is_, span: var _2), Token(k: K.flags, span: var _3), ...var rest2]:
					attrs.isFlags = Span.range(_2, _3);
					rest = rest2;
				case [Token(k: K.is_, span: var _2), Token(k: K.strong, span: var _3), ...var rest2]:
					attrs.isStrong = Span.range(_2, _3);
					rest = rest2;
				case [Token(k: K.is_, span: var _2), Token(k: K.uncounted, span: var _3), ...var rest2]:
					attrs.isUncounted = Span.range(_2, _3);
					rest = rest2;
				
				default: break loop;
			}

			return switch(nextDeclBody(rest)) {
				Success(made: var body, rest: var rest2) => Success(
					Kind(_1, attrs,
						typevars: typevars,
						name: name,
						params: params,
						repr: repr,
						parents: parents,
						body: body
					),
					rest2
				),
				var err => err.cast()
			};
		
		case var err: return err.fatalIfBad(tokens).cast();
	}
}

Result<Member> parseMemberDecl(Span _1, Tokens tokens) {
	throw "";
}

Result<Case> parseCaseDecl(Span _1, Tokens tokens) {
	throw "";
}


/* SIGS */


/* METHODS */

Result<Method> parseMethodDecl(Typevars typevars, Span _1, Tokens tokens) {
	throw "";
}


/* INITS */

Result<Init> parseInitDecl(Typevars typevars, Span _1, Tokens tokens) {
	throw "";
}


/* OPERATORS */

Result<Operator> parseOperatorDecl(Typevars typevars, Span _1, Tokens tokens) {
	throw "";
}


/* DEINITS */

Result<Deinit> parseDeinitDecl(Span _1, Tokens tokens) {
	throw "";
}


/* TYPES */

Result<(Span, List<Type>)> parseTypeParents(Tokens tokens, [bool allowEOL = false]) {
	switch(tokens) {
		case [Token(k: K.of, span: var _1), ...var rest]: switch(parseType(rest)) {
			case Success(made: var type, rest: var rest2):
				final parents = [type];

				loop: while(true) {
					if(rest2 case [Token(k: K.comma), ...var rest3]) {
						switch(parseType(rest3)) {
							case Success(:var made, rest: var rest4):
								parents.add(made);
								rest2 = rest4;
							case _ when allowEOL: break loop;
							case var err: return err.fatalIfBad(tokens).cast();
						}
					} else {
						break loop;
					}
				}

				return Success((_1, parents), rest2);
			
			case var err: return err.fatalIfBad(rest).cast();
		}

		default: return Failure(tokens, null);
	}
}

Result<(Ident name, TypeParams? params)> parseTypeDeclName(Tokens tokens) => switch(tokens) {
	[TTypename(:var span, :var name), ...var rest] => switch(parseTypeArgs(rest)) {
		Success(made: var params, rest: var rest2) => Success(((name: name, span: span), params), rest2),
		Failure() => Success(((name: name, span: span), null), rest),
		var err => err.cast()
	},
	_ => Failure(tokens, null)
};

Result<TypeSpec> parseTypeSpec(Tokens tokens) {
	switch(tokens) {
		case [Token(k: K.hashLBracket, span: var begin), ...var rest]:
			final types = <Type>[];

			while(true) switch(parseType(rest)) {
				case Success(made: var type, rest: var rest2):
					types.add(type);

					switch(rest2) {
						case [Token(k: K.rbracket, span: var end), ...var rest3]: return Success(ManyTypes(begin, types, end), rest3);
						case []: return EndOfInput(tokens);
						case [var t] when t.isAnySep: return EndOfInput(tokens);
						case [var t, ...var rest3] when t.isAnySep: rest = rest3;
						default: return Fatal(tokens, rest2);
					}
				
				case var err: return err.cast();
			}

		default: return switch(parseType(tokens)) {
			Success(:var made, :var rest) => Success(OneType(made), rest),
			var err => err.cast()
		};
	}
}

Result<Type> parseType(Tokens tokens, [bool allowSingleWildcard = false]) {
	var rest = tokens;
	
	List<Span>? leading = null;
	if(rest case [Token(k: K.wildcard, span: var _1), ...var rest2]) switch(parseTypeArgs(rest2)) {
		case Success(made: var args, rest: var rest3):
			return allowSingleWildcard? Success(Type.blank(_1, args), rest3) : Failure(tokens, rest2);
		
		case Failure(): switch(rest2) {
			case [Token(k: K.dot), ...var rest3 && [Token(k: K.typename), ..._]]:
				rest = rest3;
				leading = [_1];
			case [Token(k: K.dot), Token(k: K.wildcard), ..._]:
				leading = [_1];
			default:
				return allowSingleWildcard? Success(Type.blank(_1), rest2) : Failure(tokens, null);
		}

		case var err: return err.cast();
	}
	
	if(leading != null) loop: while(true) switch(rest) {
		case [Token(k: K.wildcard, span: var _1), Token(k: K.dot), ...var rest2]:
			leading.add(_1);
			rest = rest2;
		case [Token(k: K.wildcard), ..._]: return Failure(tokens, rest);
		default: break loop;
	}

	return switch(parseTypeSeg(rest)) {
		Success(made: var first, rest: var rest2) => switch(rest2) {
			[Token(k: K.dot), Token(k: K.typename), ..._] => switch(parseTypeSegs(rest2)) {
				Success(made: var segs, rest: var rest3) => Success(Type.path(segs..insert(0, first), leading), rest3),
				Failure() => Success(Type.path([first], leading), rest2),
				var err => err.cast()
			},
			_ => Success(Type.path([first], leading), rest2)
		},
		var err => err.cast()
	};
}

Result<TypeSeg> parseTypeSeg(Tokens tokens) => switch(tokens) {
	[TTypename(span: var _1, :var name), ...var rest] => switch(parseTypeArgs(rest)) {
		Success(made: var args, rest: var rest2) => Success(TypeSeg((name: name, span: _1), args), rest2),
		Failure() => Success(TypeSeg((name: name, span: _1)), rest),
		var err => err.cast()
	},
	_ => Failure(tokens, null)
};

Result<List<TypeSeg>> parseTypeSegs(Tokens tokens) => switch(tokens) {
	[Token(k: K.dot), ...var rest] => switch(parseTypeSeg(rest)) {
		Success(made: var seg, rest: var rest2) => switch(parseTypeSegs(rest2)) {
			Success(made: var segs, rest: var rest3) => Success(segs..insert(0, seg), rest3),
			Failure() => Success([seg], rest2),
			var err => err
		},
		var err => err.cast()
	},
	_ => Failure(tokens, null)
};

Result<Delims<List<Type>>> parseTypeArgs(Tokens tokens) {
	switch(tokens) {
		case [Token(k: K.lbracket, span: var begin), ...var rest]:
			final types = <Type>[];

			while(true) switch(parseType(rest)) {
				case Success(made: var type, rest: var rest2):
					types.add(type);

					switch(rest2) {
						case [Token(k: K.rbracket, span: var end), ...var rest3]: return Success((begin: begin, of: types, end: end), rest3);
						case []: return EndOfInput(tokens);
						case [var t] when t.isAnySep: return EndOfInput(tokens);
						case [Token(k: K.name || K.label || K.punned), ..._] when types.length == 1: return Failure(tokens, rest2);
						case [var t, ...var rest3] when t.isAnySep: rest = rest3;
						default: return Fatal(tokens, rest2);
					}
				
				case var err: return err.cast();
			}

		default: return Failure(tokens, null);
	}
}

Result<Type> parseTypeAnno(Tokens tokens, [bool allowSingleWildcard = false]) => switch(tokens) {
	[Token(k: K.lparen)] => EndOfInput(tokens),
	[Token(k: K.lparen), ...var rest] => switch(parseType(rest, allowSingleWildcard)) {
		Success(made: var type, rest: [Token(k: K.rparen), ...var rest2]) => Success(type, rest2),
		Success(rest: []) => EndOfInput(tokens),
		Success(rest: var rest2) => Fatal(tokens, rest2),
		var err => err
	},
	_ => Failure(tokens, null)
};

// ...

Result<List<StrPart>> parseStrSegs(List<StrSegment> segs) => throw "";