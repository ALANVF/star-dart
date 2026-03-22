import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'package:star/errors/errors.dart';
import 'package:star/lexing/lexing.dart';
import 'package:star/ast/ast.dart';

import 'result.dart';

typedef Typevars = List<Typevar>;
typedef T = Token;

Program parse(Tokens tokens) => switch(tokens) {
	[T(k: K.lsep), ...var rest] => parse(rest),
	[T(use: var _1?), TLitsym(name: "script", span: var _2), ...var rest] => parseScript(_1, _2, rest),
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
			case Success(s: (var decl, var rest)):
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
					case [] || [T(k: K.lsep)]: break loop;
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
					case [] || [T(k: K.lsep)]: break loop;
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
					case [] || [T(k: K.lsep)]: break loop;
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
		case [T(lbrace: var begin?), T(rbrace: var end?), ...var rest]:
			return Success(Delims(begin, [], end), rest);
		case [T(lbrace: var begin?), ...var rest]:
			final decls = <Decl>[];
			while(true) switch(nextDecl([], rest)) {
				case Success(s: (var decl, var rest2)):
					decls.add(decl);
	
					switch(rest2) {
						case [T(rbrace: var end?), ...var rest3]: return Success(Delims(begin, decls, end), rest3);
						case []: return EndOfInput(tokens);
						case [T(isAnySep: true), ...var rest3]: rest = rest3;
						default: return Fatal(tokens, rest2);
					}
				
				case var err: return err.cast();
			}
		default: return Failure(tokens, null);
	}
}

Result<Decl> nextDecl(Typevars typevars, Tokens tokens) => switch(tokens) {
	[T(type: var _1?), ...var rest] => switch(parseTypevar(_1, rest)) {
		Success(s: (var tvar, [T(isAnySep: true), ...var rest2])) => nextDecl(typevars..add(tvar), rest2),
		Success(s: (_, var rest2)) => Fatal(tokens, rest2),
		var err => err.cast()
	},
	[T(use: var _1?), TLitsym(span: var _2, :var name), T(isAnySep: true), ...var rest] =>
		parseUsePragma(typevars, _1, _2, name, rest),
	[T(use: var _1?), ...var rest] => parseUseDecl(typevars, _1, rest).fatalIfBad(tokens),
	[T(alias: var _1?), ...var rest] => parseAliasDecl(typevars, _1, rest).fatalIfBad(tokens),
	[T(module: var _1?), ...var rest] => parseModuleDecl(typevars, _1, rest).fatalIfBad(tokens),
	[T(class_: var _1?), ...var rest] => parseClassDecl(typevars, _1, rest).fatalIfBad(tokens),
	[T(protocol: var _1?), ...var rest] => parseProtocolDecl(typevars, _1, rest).fatalIfBad(tokens),
	[T(category: var _1?), ...var rest] => parseCategoryDecl(typevars, _1, rest).fatalIfBad(tokens),
	[T(kind: var _1?), ...var rest] => parseKindDecl(typevars, _1, rest).fatalIfBad(tokens),
	[T(my: var _1?), ...var rest] => typevars.isEmpty
		? parseMemberDecl(_1, rest).fatalIfBad(tokens)
		: FatalError(StarError.noGenericMember(_1)),
	[T(has: var _1?), ...var rest] => typevars.isEmpty
		? parseCaseDecl(_1, rest).fatalIfBad(tokens)
		: FatalError(StarError.noGenericCase(_1)),
	[T(init: var _1?), ...var rest] => parseInitDecl(typevars, _1, rest).fatalIfBad(tokens),
	[T(on: var _1?), ...var rest] => parseMethodDecl(typevars, _1, rest).fatalIfBad(tokens),
	[T(operator: var _1?), ...var rest] => parseOperatorDecl(typevars, _1, rest).fatalIfBad(tokens),
	[T(deinit: var _1?), ...var rest] => typevars.isEmpty
		? parseDeinitDecl(_1, rest).fatalIfBad(tokens)
		: FatalError(StarError.noGenericDeinit(_1)),
	[_, ...] => Fatal(tokens, null),
	[] => EndOfInput(tokens)
};


/* TYPEVARS */

Result<Typevar> parseTypevar(Span _1, Tokens tokens) {
	switch(parseTypeDeclName(tokens)) {
		case Success(s: ((var name, var params), var rest)):
			List<Type>? parents; switch(parseTypeParents(rest)) {
				case Success(s: (var made, var rest2)):
					rest = rest2;
					parents = made.$2;
				case Failure(): parents = null;
				case var err: return err.cast();
			}

			final attrs = TypevarAttrs();

			loop: while(true) switch(rest) {
				case [T(is_: var _2?), T(native: var _3?), ...var rest2]:
					throw "nyi";
				case [T(is_: var _2?), T(flags: var _3?), ...var rest2]:
					attrs.isFlags = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(strong: var _3?), ...var rest2]:
					attrs.isStrong = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(uncounted: var _3?), ...var rest2]:
					attrs.isUncounted = Span.range(_2, _3);
					rest = rest2;
				
				default: break loop;
			}

			(Span, TypevarRule)? rule; if(rest case [T(if_: var _2?), ...var rest2]) {
				switch(parseTypevarRule(rest2)) {
					case Success(s: (var made, var rest3)):
						rule = (_2, made);
						rest = rest3;
					case var err: return err.cast();
				}
			} else {
				rule = null;
			}

			Body? body; switch(nextDeclBody(rest)) {
				case Success(s: (var made, var rest2)):
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

Result<TypevarRule> parseTypevarRule(Tokens tokens) => switch(parseTypevarRuleTerm(tokens)) {
	Success(:var made, :var rest) => parseTypevarRuleCond(made, rest).updateIfBad(tokens),
	var err => err.updateIfBad(tokens)
};

Result<TypevarRule> parseTypevarRuleCond(TypevarRule left, Tokens tokens) => switch(tokens) {
	[T(k: K.andAnd, :var span), ...var rest] => switch(parseTypevarRuleTerm(rest)) {
		Success(s: (var right, var rest2)) => parseTypevarRuleCond(TypevarRule.logic(left, (span, R_Logic.and), right), rest2),
		var err => err
	},
	[T(k: K.barBar, :var span), ...var rest] => switch(parseTypevarRuleTerm(rest)) {
		Success(s: (var right, var rest2)) => parseTypevarRuleCond(TypevarRule.logic(left, (span, R_Logic.or), right), rest2),
		var err => err
	},
	[T(k: K.caretCaret, :var span), ...var rest] => switch(parseTypevarRuleTerm(rest)) {
		Success(s: (var right, var rest2)) => parseTypevarRuleCond(TypevarRule.logic(left, (span, R_Logic.xor), right), rest2),
		var err => err
	},
	[T(k: K.bangBang, :var span), ...var rest] => switch(parseTypevarRuleTerm(rest)) {
		Success(s: (var right, var rest2)) => parseTypevarRuleCond(TypevarRule.logic(left, (span, R_Logic.nor), right), rest2),
		var err => err
	},
	_ => Success(left, tokens)
};

const _cmpMap = const {
	K.lt: R_Cmp.lt,
	K.ltEq: R_Cmp.le,
	K.gt: R_Cmp.gt,
	K.gtEq: R_Cmp.ge
};
Result<TypevarRule> parseTypevarRuleTerm(Tokens tokens) {
	switch(tokens) {
		case [T(lparen: var _1?), ...var rest]:
			return parseTypevarRuleParen(_1, rest);
		
		case [T(bang: var _1?), T(lparen: var _2?), ...var rest]:
			return switch(parseTypevarRuleParen(_2, rest)) {
				Success(s: (var made, var rest2)) => Success(TypevarRule.not(_1, made), rest2),
				var err => err
			};

		case [T(bang: var _1?), ...var rest]:
			return switch(parseType(rest, true)) {
				Success(s: (var made, var rest2)) => Success(TypevarRule.negate(_1, made), rest2),
				var err => err.cast()
			};
		
		case [T(k: K.typename || K.wildcard), ...]: switch(parseType(tokens, true)) {
			case Success(s: (var type1, var rest)): switch(rest) {
				case [T(question: var _1?), ...var rest2]:
					return Success(TypevarRule.exists(type1, _1), rest2);
				
				// TODO: condense all 3 of these together
				case [T(questionEq: var _1?), ...var rest2]: switch(parseType(rest2, true)) {
					case Success(s: (var type2, var rest3)):
						final chain = [(_1, type2)];

						while(true) {
							if(rest3 case [T(questionEq: var _2?), ...var rest4]) {
								switch(parseType(rest4, true)) {
									case Success(s: (var type3, var rest5)):
										rest3 = rest5;
										chain.add((_2, type3));							
									case var err: return err.cast();
								}
							} else {
								break;
							}
						}

						return Success(TypevarRule.test(type1, R_Test.eq, chain), rest3);
					
					case var err: return err.cast();
				}

				case [T(bangEq: var _1?), ...var rest2]: switch(parseType(rest2, true)) {
					case Success(s: (var type2, var rest3)):
						final chain = [(_1, type2)];

						while(true) {
							if(rest3 case [T(bangEq: var _2?), ...var rest4]) {
								switch(parseType(rest4, true)) {
									case Success(s: (var type3, var rest5)):
										rest3 = rest5;
										chain.add((_2, type3));							
									case var err: return err.cast();
								}
							} else {
								break;
							}
						}

						return Success(TypevarRule.test(type1, R_Test.ne, chain), rest3);
					
					case var err: return err.cast();
				}

				case [T(of: var _1?), ...var rest2]: switch(parseType(rest2, true)) {
					case Success(s: (var type2, var rest3)):
						final chain = [(_1, type2)];

						while(true) {
							if(rest3 case [T(of: var _2?), ...var rest4]) {
								switch(parseType(rest4, true)) {
									case Success(s: (var type3, var rest5)):
										rest3 = rest5;
										chain.add((_2, type3));							
									case var err: return err.cast();
								}
							} else {
								break;
							}
						}

						return Success(TypevarRule.test(type1, R_Test.of, chain), rest3);
					
					case var err: return err.cast();
				}

				case [T(t: (var op && (K.lt || K.ltEq || K.gt || K.gtEq), var _1)), ...var rest2]: switch(parseType(rest2, true)) {
					case Success(s: (var type2, var rest3)):
						final chain = [(_1, _cmpMap[op]!, type2)];

						while(true) {
							if(rest3 case [T(t: (var op2 && (K.lt || K.ltEq || K.gt || K.gtEq), var _2)), ...var rest4]) {
								switch(parseType(rest4, true)) {
									case Success(s: (var type3, var rest5)):
										rest3 = rest5;
										chain.add((_2, _cmpMap[op2]!, type3));							
									case var err: return err.cast();
								}
							} else {
								break;
							}
						}

						return Success(TypevarRule.cmp(type1, chain), rest3);
					
					case var err: return err.cast();
				}

				case []: return EndOfInput(tokens);
				default: return Failure(tokens, rest);
			}

			case var err: return err.cast();
		}

		case []: return EndOfInput(tokens);
		default: return Failure(tokens, null);
	}
}

Result<TypevarRule> parseTypevarRuleParen(Span _1, Tokens tokens) {
	if(tokens.firstOrNull?.k == K.rparen) return Fatal(tokens, null);

	var rest = tokens;
	var inner = <Token>[];
	var level = 1;

	loop: while(level > 0) switch(rest.firstOrNull?.k) {
		case null: return EndOfInput(tokens);
		case K.lsep: [_, ...rest] = rest;
		case var k:
			if(k == K.lparen) level++; else
			if(k == K.rparen && level-- == 0) break loop;

			inner.add(rest.first);
			[_, ...rest] = rest;
	}

	// ???
	rest = inner + rest;

	final oldRest = rest;
	final leadingOp = switch(rest.firstOrNull?.k) {
		K.andAnd => R_Logic.and,
		K.barBar => R_Logic.or,
		K.caretCaret => R_Logic.xor,
		K.bangBang => R_Logic.nor,
		_ => null
	};
	if(leadingOp != null) [_, ...rest] = rest;

	return switch(parseTypevarRule(rest)) {
		Success(made: RLogic(op: (_, var op))) when leadingOp != null && op != leadingOp => Fatal(tokens, oldRest),
		Success(s: (var made, [T(rparen: var _2?), ...var rest2])) => Success(TypevarRule.paren(_1, made, _2), rest2),
		Success(rest: var rest2) => Fatal(tokens, rest2),
		var err => err.fatalIfBad(tokens)
	};
}

/* IMPORTS */

Result<Use> parseUsePragma(Typevars typevars, Span _1, Span _2, String sym, Tokens tokens) {
	return Success(Use(_1, UseKind.pragma(Ident(sym, _2)), typevars: typevars), tokens);
}

Result<Use> parseUseDecl(Typevars typevars, Span _1, Tokens tokens) {
	switch(parseUseTree(tokens)) {
		case Success(s: (var spec, var rest)):
			UseFrom? from = null; switch(rest) {
				case [TLabel(n: (var _2, "from")), TStr(span: var _3, :var segs), ...var rest2]: switch(parseStrSegs(segs)) {
					case Success(s: ([Left(v: var path)], var rest3)):
						rest = rest3;
						from = UseFrom.file(_2, (_3, path));
					case Success(): return Fatal(tokens, rest2); // TODO: custom error message
					case var err: return err.fatalIfBad(tokens).cast();
				}
				case [TLabel(n: (var _2, "from")), ...var rest2]: switch(parseType(rest2)) {
					case Success(s: (var type, var rest3)):
						rest = rest3;
						from = UFType(_2, type);
					case var err: return err.fatalIfBad(tokens).cast();
				}
			}

			if(rest case [TLabel(n: (var _2, "as")), ...var rest2]) {
				return switch(parseUseTree(rest2)) {
					Success(s: (var tree, var rest3)) => Success(Use(_1, UseKind.import(spec, from, (_2, tree)), typevars: typevars), rest3),
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
		case [T(k: K.hashLBracket), ...var rest]:
			final types = <Type>[];

			while(true) switch(parseType(rest)) {
				case Success(s: (var type, var rest2)):
					types.add(type);

					switch(rest2) {
						case [T(k: K.rbracket), ...var rest3]: return Success(UTTypes(types), rest3);
						case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
						case [T(isAnySep: true), ...var rest3]: rest = rest3;
						default: return Fatal(tokens, rest2);
					}
				
				case var err: return err.cast();
			}
		
		case [T(k: K.hashLParen), ...var rest]:
			final pairs = <(Type, Span, UseTree)>[];

			while(true) switch(parseType(rest)) {
				case Success(s: (var type, var rest2)): switch(rest2) {
					case [T(eqGt: var _1?), ...var rest3]: switch(parseUseTree(rest3)) {
						case Success(s: (var tree, var rest4)):
							pairs.add((type, _1, tree));

							switch(rest4) {
								case [T(k: K.rparen), ...var rest5]: return Success(UTMap(pairs), rest5);
								case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
								case [T(isAnySep: true), ...var rest5]: rest = rest5;
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
				Success(s: (var type, var rest)) => Success(UTType(type), rest),
				var err => err.cast()
			};
	}
}


/* TYPE DECLS */

Result<Alias> parseAliasDecl(Typevars typevars, Span _1, Tokens tokens) {
	switch(parseTypeDeclName(tokens)) {
		case Success(s: ((var name, var params), var rest)):
			final attrs = AliasAttrs();

			switch(parseTypeAnno(rest)) {
				case Success(s: (var type, var rest2)):
					loop: while(true) switch(rest2) {
						case [T(is_: var _2?), T(hidden: var _3?), ...var rest3]:
							switch(parseType(rest2)) {
								case Success(s: (var made, var rest4)):
									attrs.isHidden = (Span.range(_2, _3), made);
									rest2 = rest4;
								case Failure():
									attrs.isHidden = (Span.range(_2, _3), null);
									rest2 = rest3;
								case var err: return err.cast();
							}
						case [T(is_: var _2?), T(friend: var _3?), ...var rest3]:
							switch(parseTypeSpec(rest3)) {
								case Success(s: (var made, var rest4)):
									attrs.isFriend = (Span.range(_2, _3), made);
									rest2 = rest4;
								case var err: return err.cast();
							}
						case [T(is_: var _2?), T(noinherit: var _3?), ...var rest3]:
							attrs.isNoinherit = Span.range(_2, _3);
							rest2 = rest3;
						
						default: break loop;
					}

					final Body? body; switch(nextDeclBody(rest2)) {
						case Success(s: (var made, var rest3)):
							rest2 = rest3;
							body = made;
						case Failure(): body = null;
						case var err: return err.cast();
					}

					return Success(
						Alias(_1, attrs, AliasKind.strong(type, body),
							typevars: typevars,
							name: name,
							params: params
						),
						rest2
					);
				
				case Failure():
					loop: while(true) switch(rest) {
						case [T(is_: var _2?), T(hidden: var _3?), ...var rest2]:
							switch(parseType(rest2)) {
								case Success(s: (var made, var rest3)):
									attrs.isHidden = (Span.range(_2, _3), made);
									rest = rest3;
								case Failure():
									attrs.isHidden = (Span.range(_2, _3), null);
									rest = rest2;
								case var err: return err.cast();
							}
						case [T(is_: var _2?), T(friend: var _3?), ...var rest2]:
							switch(parseTypeSpec(rest2)) {
								case Success(s: (var made, var rest3)):
									attrs.isFriend = (Span.range(_2, _3), made);
									rest = rest3;
								case var err: return err.cast();
							}
						case [T(is_: var _2?), T(noinherit: var _3?), ...var rest2]:
							attrs.isNoinherit = Span.range(_2, _3);
							rest = rest2;
						
						default: break loop;
					}

					switch(rest) {
						case [T(k: K.eq)]: return EndOfInput(tokens);
						case [T(k: K.eq), ...var rest2]: return switch(parseType(rest2)) {
							Success(s: (var type, var rest3)) => Success(
								Alias(_1, attrs, AliasKind.direct(type),
									typevars: typevars,
									name: name,
									params: params
								),
								rest3
							),
							var err => err.cast()
						};
						default:
							final Body? body; switch(nextDeclBody(rest)) {
								case Success(s: (var made, var rest2)):
									rest = rest2;
									body = made;
								case Failure(): body = null;
								case var err: return err.cast();
							}

							return Success(
								Alias(_1, attrs, AliasKind.opaque(body),
									typevars: typevars,
									name: name,
									params: params
								),
								rest
							);
					}
				
				case var err: return err.cast();
			}
		
		case var err: return err.fatalIfBad(tokens).cast();
	}
}

Result<Module> parseModuleDecl(Typevars typevars, Span _1, Tokens tokens) {
	switch(parseTypeDeclName(tokens)) {
		case Success(s: ((var name, var params), var rest)):
			List<Type>? parents; switch(parseTypeParents(rest)) {
				case Success(s: (var made, var rest2)):
					rest = rest2;
					parents = made.$2;
				case Failure(): parents = null;
				case var err: return err.cast();
			}

			final attrs = ModuleAttrs();

			loop: while(true) switch(rest) {
				case [T(is_: var _2?), T(hidden: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(sealed: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isSealed = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isSealed = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(main: var _3?), ...var rest2]:
					attrs.isMain = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(friend: var _3?), ...var rest2]:
					switch(parseTypeSpec(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isFriend = (Span.range(_2, _3), made);
							rest = rest3;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(native: var _3?), TLitsym(span: var _4, :var name), ...var rest2]:
					attrs.isNative = (Span.range(_2, _3), Ident(name, _4));
					rest = rest2;
				
				default: break loop;
			}

			return switch(nextDeclBody(rest)) {
				Success(s: (var body, var rest2)) => Success(
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
		case Success(s: ((var name, var params), var rest)):
			List<Type>? parents; switch(parseTypeParents(rest)) {
				case Success(s: (var made, var rest2)):
					rest = rest2;
					parents = made.$2;
				case Failure(): parents = null;
				case var err: return err.cast();
			}

			final attrs = ClassAttrs();

			loop: while(true) switch(rest) {
				case [T(is_: var _2?), T(hidden: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(sealed: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isSealed = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isSealed = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(friend: var _3?), ...var rest2]:
					switch(parseTypeSpec(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isFriend = (Span.range(_2, _3), made);
							rest = rest3;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(strong: var _3?), ...var rest2]:
					attrs.isStrong = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(uncounted: var _3?), ...var rest2]:
					attrs.isUncounted = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(k: K.native), T(lbracket: var begin?), ...var rest2]:
					final spec = <(Ident, Expr)>[];
					if(rest2 case [TLabel(n: (var _3, var label)), ...var rest3]) {
						switch(parseBasicExpr(rest3)) {
							case Success(s: (var made, var rest4)):
								spec.add((Ident(label, _3), made));
								rest2 = rest4;
							case var err: return err.cast();
						}
					} else {
						return Fatal(tokens, rest2);
					}

					loop: while(true) switch(rest2) {
						case [T(rbracket: var end?), ...var rest3]:
							attrs.isNative = Delims(Span.range(_2, begin), spec, end);
							rest = rest3;
							break loop;
						
						case [T(isAnySep: true), ...var rest3]:
						case var rest3:
							if(rest3 case [TLabel(n: (var _3, var label)), ...var rest4]) {
								switch(parseBasicExpr(rest4)) {
									case Success(s: (var made, var rest5)):
										rest2 = rest5;
										spec.add((Ident(label, _3), made));
									case var err: return err.cast();
								}
							} else {
								return Fatal(tokens, rest3);
							}
					}
				
				default: break loop;
			}

			return switch(nextDeclBody(rest)) {
				Success(s: (var body, var rest2)) => Success(
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
		case Success(s: ((var name, var params), var rest)):
			List<Type>? parents; switch(parseTypeParents(rest)) {
				case Success(s: (var made, var rest2)):
					rest = rest2;
					parents = made.$2;
				case Failure(): parents = null;
				case var err: return err.cast();
			}

			final attrs = ProtocolAttrs();

			loop: while(true) switch(rest) {
				case [T(is_: var _2?), T(hidden: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(sealed: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isSealed = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isSealed = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(friend: var _3?), ...var rest2]:
					switch(parseTypeSpec(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isFriend = (Span.range(_2, _3), made);
							rest = rest3;
						case var err: return err.cast();
					}
				
				default: break loop;
			}

			return switch(nextDeclBody(rest)) {
				Success(s: (var body, var rest2)) => Success(
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
	switch(parseType(tokens)) {
		case Success(s: (var path, var rest)):
			final Type? type; if(rest case [T(k: K.for_), ...var rest2]) {
				switch(parseType(rest2)) {
					case Success(s: (var made, var rest3)):
						rest = rest3;
						type = made;
					case var err: return err.cast();
				}
			} else {
				type = null;
			}

			final attrs = CategoryAttrs();

			loop: while(true) switch(rest) {
				case [T(is_: var _2?), T(hidden: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(friend: var _3?), ...var rest2]:
					switch(parseTypeSpec(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isFriend = (Span.range(_2, _3), made);
							rest = rest3;
						case var err: return err.cast();
					}
				
				default: break loop;
			}

			return switch(nextDeclBody(rest)) {
				Success(s: (var body, var rest2)) => Success(
					Category(_1, attrs,
						typevars: typevars,
						path: path,
						target: type,
						body: body
					),
					rest2
				),
				var err => err.cast()
			};
		
		case var err: return err.fatalIfBad(tokens).cast();
	}
}

Result<Kind> parseKindDecl(Typevars typevars, Span _1, Tokens tokens) {
	switch(parseTypeDeclName(tokens)) {
		case Success(s: ((var name, var params), var rest)):
			Type? repr; switch(parseTypeAnno(tokens)) {
				case Success(s: (var made, var rest2)):
					rest = rest2;
					repr = made;
				case Failure(): repr = null;
				case var err: return err.cast();
			}

			List<Type>? parents; switch(parseTypeParents(rest)) {
				case Success(s: (var made, var rest2)):
					rest = rest2;
					parents = made.$2;
				case Failure(): parents = null;
				case var err: return err.cast();
			}

			final attrs = KindAttrs();

			loop: while(true) switch(rest) {
				case [T(is_: var _2?), T(hidden: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(sealed: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isSealed = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isSealed = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(friend: var _3?), ...var rest2]:
					switch(parseTypeSpec(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isFriend = (Span.range(_2, _3), made);
							rest = rest3;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(flags: var _3?), ...var rest2]:
					attrs.isFlags = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(strong: var _3?), ...var rest2]:
					attrs.isStrong = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(uncounted: var _3?), ...var rest2]:
					attrs.isUncounted = Span.range(_2, _3);
					rest = rest2;
				
				default: break loop;
			}

			return switch(nextDeclBody(rest)) {
				Success(s: (var body, var rest2)) => Success(
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
	switch(tokens) {
		case [T(asSoftName: TName(span: var _2, :var name)), ...var rest]:
			final Type? type; switch(parseTypeAnno(rest)) {
				case Success(s: (var made, var rest2)):
					rest = rest2;
					type = made;
				case Failure(): type = null;
				case var err: return err.cast();
			}

			final attrs = MemberAttrs();

			loop: while(true) switch(rest) {
				case [T(is_: var _2?), T(static: var _3?), ...var rest2]:
					attrs.isStatic = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(hidden: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(readonly: var _3?), ...var rest2]:
					attrs.isReadonly = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(getter: var _3?), TLitsym(span: var _4, name: var sym), ...var rest2]:
					attrs.isGetter = (Span.range(_2, _3), Ident(sym, _4));
					rest = rest2;
				case [T(is_: var _2?), T(getter: var _3?), ...var rest2]:
					attrs.isGetter = (Span.range(_2, _3), null);
					rest = rest2;
				case [T(is_: var _2?), T(setter: var _3?), TLitsym(span: var _4, name: var sym), ...var rest2]:
					attrs.isSetter = (Span.range(_2, _3), Ident(sym, _4));
					rest = rest2;
				case [T(is_: var _2?), T(setter: var _3?), ...var rest2]:
					attrs.isSetter = (Span.range(_2, _3), null);
					rest = rest2;
				case [T(is_: var _2?), T(noinherit: var _3?), ...var rest2]:
					attrs.isNoinherit = Span.range(_2, _3);
					rest = rest2;
				
				default: break loop;
			}

			final Expr? value; if(rest case [T(k: K.eq), ...var rest2]) {
				switch(parseFullExpr(rest2)) {
					case Success(s: (var made, var rest3)):
						rest = rest3;
						value = reparseExpr(made);
					case var err: return err.cast();
				}
			} else {
				value = null;
			}

			return Success(
				Member(_1, attrs,
					name: Ident(name, _2),
					type: type,
					value: value
				),
				rest
			);
		
		case []: return EndOfInput(tokens);
		default: return Fatal(tokens, null);
	}
}

Result<Case> parseCaseDecl(Span _1, Tokens tokens) {
	switch(tokens) {
		case [T(asAnyName: TName(span: var _2, :var name)), ...var rest]:
			final Expr? value; if(rest case [T(k: K.eqGt), ...var rest2]) {
				switch(parseExpr(rest2)) {
					case Success(s: (var made, var rest3)):
						rest = rest3;
						value = made;
					case var err: return err.cast();
				}
			} else {
				value = null;
			}

			final Block? init; switch(parseBlock(rest)) {
				case Success(s: (var made, var rest2)):
					rest = rest2;
					init = made;
				case Failure(): init = null;
				case var err: return err.cast();
			}

			return Success(
				Case(_1, CaseKind.scalar(Ident(name, _2), value), init),
				rest
			);
		
		case [T(lbracket: var begin?), ...var rest && [TLabel(), ...]]:
			switch(parseMultiSig(rest)) {
				case Success(s: ((var params, var end), var rest2)):
					final Message<Type>? assoc; switch(rest2) {
						case [T(k: K.eqGt), T(k: K.lbracket), ...var rest3]: switch(finishTypeMsg(rest3)) {
							case Success(s: (var made, var rest4)):
								rest2 = rest4;
								(assoc, _) = made;
							case var err: return err.fatalIfBad(rest2).cast();
						}
						case [T(k: K.eqGt), ...var rest3]: return Fatal(rest2, rest3);
						default: assoc = null;
					}

					final Block? init; switch(parseBlock(rest2)) {
						case Success(s: (var made, var rest3)):
							rest2 = rest3;
							init = made;
						case Failure(): init = null;
						case var err: return err.cast();
					}

					return Success(
						Case(_1, CaseKind.tagged(Delims(begin, CaseTag.multi(params), end), assoc), init),
						rest2
					);
				
				case var err: return err.fatalIfBad(tokens).cast();
			}

		case [T(lbracket: var begin?), T(asAnyName: TName(span: var _2, :var name)), T(rbracket: var end?), ...var rest]:
			final Message<Type>? assoc; switch(rest) {
				case [T(k: K.eqGt), T(k: K.lbracket), ...var rest2]: switch(finishTypeMsg(rest2)) {
					case Success(s: (var made, var rest3)):
						rest = rest3;
						(assoc, _) = made;
					case var err: return err.fatalIfBad(rest).cast();
				}
				case [T(k: K.eqGt), ...var rest2]: return Fatal(rest, rest2);
				default: assoc = null;
			}

			final Block? init; switch(parseBlock(rest)) {
				case Success(s: (var made, var rest2)):
					rest = rest2;
					init = made;
				case Failure(): init = null;
				case var err: return err.cast();
			}

			return Success(
				Case(_1, CaseKind.tagged(Delims(begin, CaseTag.single(Ident(name, _2)), end), assoc), init),
				rest
			);
		
		case []: return EndOfInput(tokens);
		default: return Fatal(tokens, null);
	}
}

/* SIGS */

Result<(List<MultiParam> params, Span end)> parseMultiSig(Tokens tokens) {
	var rest = tokens;
	final params = <MultiParam>[];

	while(true) {
		if(params.isNotEmpty) switch(rest) {
			case [T(rbracket: var end?), ...var rest2]: return Success((params, end), rest2);
			case [T(isAnySep: true), ...var rest2]: rest = rest;
			case [TLabel(), ...]: ;
			case []: return EndOfInput(tokens);
			default: return Fatal(tokens, rest);
		}

		switch(rest) {
			case [TLabel(n: (var _2, var label)), ...var rest2 && [T(k: K.lparen), ...]]: switch(parseTypeAnno(rest2, true)) {
				case Success(s: (var type, [T(k: K.eq), ...var rest3])): switch(parseExpr(rest3)) {
					case Success(s: (var expr, var rest4)):
						rest = rest4;
						params.add((label: Ident(label, _2), name: null, type: type, value: expr));
					case var err: return err.fatalIfFailed().cast();
				}
				case Success(s: (var type, var rest3)):
					rest = rest3;
					params.add((label: Ident(label, _2), name: null, type: type, value: null));
				case var err: return err.fatalIfBad(tokens).cast();
			}

			case [TLabel(n: (var _2, var label)), T(asSoftName: TName(span: var _3, :var name)), ...var rest2]: switch(parseTypeAnno(rest2, true)) {
				case Success(s: (var type, [T(k: K.eq), ...var rest3])): switch(parseExpr(rest3)) {
					case Success(s: (var expr, var rest4)):
						rest = rest4;
						params.add((label: Ident(label, _2), name: Ident(name, _3), type: type, value: expr));
					case var err: return err.fatalIfFailed().cast();
				}
				case Success(s: (var type, var rest3)):
					rest = rest3;
					params.add((label: Ident(label, _2), name: Ident(name, _3), type: type, value: null));
				case var err: return err.fatalIfBad(tokens).cast();
			}

			case [TLabel(), ...var rest2]: return Fatal(tokens, rest2);

			case [T(k: K.lparen), ..._]: switch(parseTypeAnno(rest, true)) {
				case Success(s: (var type, var rest2)):
					rest = rest2;
					params.add((label: null, name: null, type: type, value: null));
				case var err: return err.fatalIfFailed().cast();
			}

			case [T(asSoftName: TName(span: var _2, :var name)), ...var rest2] when params.isNotEmpty: switch(parseTypeAnno(rest2, true)) {
				case Success(s: (var type, [T(k: K.eq), ...var rest3])): switch(parseExpr(rest3)) {
					case Success(s: (var expr, var rest4)):
						rest = rest4;
						params.add((label: null, name: Ident(name, _2), type: type, value: expr));
					case var err: return err.fatalIfFailed().cast();
				}
				case Success(s: (var type, var rest3)):
					rest = rest3;
					params.add((label: null, name: Ident(name, _2), type: type, value: null));
				case var err: return err.fatalIfBad(tokens).cast();
			}

			case []: return EndOfInput(tokens);
			default: return Fatal(tokens, rest);
		}
	}
}

/* METHODS */

Result<Method> parseMethodDecl(Typevars typevars, Span _1, Tokens tokens) {
	if(tokens case [T(lbracket: var begin?), ...var rest]) {
		final MethodKind kind;
		final Span end;
		switch(rest) {
			case [TLabel(), ...]: switch(parseMultiSig(rest)) {
				case Success(s: ((var params, var _end), var rest2)):
					rest = rest2;
					kind = MethodKind.multi(params);
					end = _end;
				case var err: return err.fatalIfBad(rest).cast();
			}
			case [T(asAnyName: TName(span: var _1, :var name)), T(rbracket: var _end?), ...var rest2]:
				rest = rest2;
				kind = MethodKind.single(Ident(name, _1));
				end = _end;
			default: switch(parseType(rest)) {
				case Success(s: (var type, [T(rbracket: var _end?), ...var rest2])):
					rest = rest2;
					kind = MethodKind.cast(type);
					end = _end;
				case Success(rest: var rest2): return Fatal(rest, rest2);
				case var err: return err.fatalIfBad(rest).cast();
			}
		}

		final Type? ret; switch(parseTypeAnno(rest)) {
			case Success(s: (var type, var rest2)):
				rest = rest2;
				ret = type;
			case Failure(): ret = null;
			case var err: return err.fatalIfBad(rest).cast();
		}

		final attrs = MethodAttrs();

		loop: while(true) switch(rest) {
			case [T(is_: var _2?), T(static: var _3?), ...var rest2]:
				attrs.isStatic = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(hidden: var _3?), ...var rest2]:
				switch(parseType(rest2)) {
					case Success(s: (var made, var rest3)):
						attrs.isHidden = (Span.range(_2, _3), made);
						rest = rest3;
					case Failure():
						attrs.isHidden = (Span.range(_2, _3), null);
						rest = rest2;
					case var err: return err.cast();
				}
			case [T(is_: var _2?), T(main: var _3?), ...var rest2]:
				attrs.isMain = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(getter: var _3?), ...var rest2]:
				attrs.isGetter = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(setter: var _3?), ...var rest2]:
				attrs.isSetter = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(noinherit: var _3?), ...var rest2]:
				attrs.isNoinherit = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(unordered: var _3?), ...var rest2]:
				attrs.isUnordered = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(native: var _3?), TLitsym(span: var _4, name: var sym), ...var rest2]:
				attrs.isNative = (Span.range(_2, _3), Ident(sym, _4));
				rest = rest2;
			case [T(is_: var _2?), T(native: var _3?), ...var rest2]:
				attrs.isNative = (Span.range(_2, _3), null);
				rest = rest2;
			case [T(is_: var _2?), T(inline: var _3?), ...var rest2]:
				attrs.isInline = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(asm: var _3?), ...var rest2]:
				attrs.isAsm = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(macro: var _3?), ...var rest2]:
				attrs.isMacro = Span.range(_2, _3);
				rest = rest2;
			
			default: break loop;
		}

		final StmtBody? body; switch(parseBody(rest)) {
			case Success(s: (var made, var rest2)):
				rest = rest2;
				body = made;
			case Failure(): body = null;
			case var err: return err.fatalIfBad(rest).cast();
		}

		return Success(
			Method(_1, attrs,
				typevars: typevars,
				spec: Delims(begin, kind, end),
				ret: ret,
				body: body
			),
			rest
		);
	} else {
		return Failure(tokens, null);
	}
}


/* INITS */

Result<Decl> parseInitDecl(Typevars typevars, Span _1, Tokens tokens) {
	switch(tokens) {
		case [T(lbracket: var begin?), ...var rest]:
			final MethodKind kind;
			final Span end;
			switch(rest) {
				case [TLabel(), ...]: switch(parseMultiSig(rest)) {
					case Success(s: ((var params, var _end), var rest2)):
						rest = rest2;
						kind = MethodKind.multi(params);
						end = _end;
					case var err: return err.fatalIfBad(rest).cast();
				}
				case [T(asAnyName: TName(span: var _1, :var name)), T(rbracket: var _end?), ...var rest2]:
					rest = rest2;
					kind = MethodKind.single(Ident(name, _1));
					end = _end;
				default: return Fatal(tokens, rest);
			}

			final attrs = InitAttrs();

			loop: while(true) switch(rest) {
				case [T(is_: var _2?), T(hidden: var _3?), ...var rest2]:
					switch(parseType(rest2)) {
						case Success(s: (var made, var rest3)):
							attrs.isHidden = (Span.range(_2, _3), made);
							rest = rest3;
						case Failure():
							attrs.isHidden = (Span.range(_2, _3), null);
							rest = rest2;
						case var err: return err.cast();
					}
				case [T(is_: var _2?), T(noinherit: var _3?), ...var rest2]:
					attrs.isNoinherit = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(unordered: var _3?), ...var rest2]:
					attrs.isUnordered = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(native: var _3?), TLitsym(span: var _4, name: var sym), ...var rest2]:
					attrs.isNative = (Span.range(_2, _3), Ident(sym, _4));
					rest = rest2;
				case [T(is_: var _2?), T(native: var _3?), ...var rest2]:
					attrs.isNative = (Span.range(_2, _3), null);
					rest = rest2;
				case [T(is_: var _2?), T(asm: var _3?), ...var rest2]:
					attrs.isAsm = Span.range(_2, _3);
					rest = rest2;
				case [T(is_: var _2?), T(macro: var _3?), ...var rest2]:
					attrs.isMacro = Span.range(_2, _3);
					rest = rest2;
				
				default: break loop;
			}

			final StmtBody? body; switch(parseBody(rest)) {
				case Success(s: (var made, var rest2)):
					rest = rest2;
					body = made;
				case Failure(): body = null;
				case var err: return err.fatalIfBad(rest).cast();
			}

			return Success(
				Init(_1, attrs,
					typevars: typevars,
					spec: Delims(begin, kind, end),
					body: body
				),
				rest
			);

		case [T(is_: var _2?), T(static: var _3?), ...var rest]: return switch(parseBody(rest)) {
			Success(s: (var body, var rest2)) => Success(
				DefaultInit(_1, EmptyMethodAttrs()..isStatic = Span.range(_2, _3), body: body),
				rest2
			),
			var err => err.fatalIfBad(rest).cast()
		};

		default: return switch(parseBody(tokens)) {
			Success(s: (var body, var rest)) => Success(
				DefaultInit(_1, EmptyMethodAttrs(), body: body),
				rest
			),
			var err => err.fatalIfBad(tokens).cast()
		};
	}
}


/* OPERATORS */

Result<Operator> parseOperatorDecl(Typevars typevars, Span _1, Tokens tokens) {
	if(tokens case [TLitsym(span: var _2, name: var sym), ...var rest]) {
		final Delims<OperatorSpec>? spec; switch(rest) {
			case [T(k: K.lbracket), T(k: K.rbracket), ...]: return Fatal(tokens, rest); // TODO: custom error message here
			case [T(lbracket: var begin?), T(asSoftName: TName(span: var _3, :var name)), ...var rest2]: switch(parseTypeAnno(rest2)) {
				case Success(s: (var type, [T(rbracket: var end?), ...var rest3])):
					rest = rest3;
					spec = Delims(begin, (name: Ident(name, _3), type: type), end);
				case Success(rest: var rest3): return Fatal(tokens, rest3);
				case var err: return err.fatalIfBad(rest2).cast();
			}
			default: spec = null;
		}

		final Type? ret; switch(parseTypeAnno(rest)) {
			case Success(s: (var type, var rest2)):
				rest = rest2;
				ret = type;
			case Failure(): ret = null;
			case var err: return err.fatalIfBad(rest).cast();
		}

		final attrs = OperatorAttrs();

		loop: while(true) switch(rest) {
			case [T(is_: var _2?), T(hidden: var _3?), ...var rest2]:
				switch(parseType(rest2)) {
					case Success(s: (var made, var rest3)):
						attrs.isHidden = (Span.range(_2, _3), made);
						rest = rest3;
					case Failure():
						attrs.isHidden = (Span.range(_2, _3), null);
						rest = rest2;
					case var err: return err.cast();
				}
			case [T(is_: var _2?), T(noinherit: var _3?), ...var rest2]:
				attrs.isNoinherit = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(native: var _3?), TLitsym(span: var _4, name: var sym), ...var rest2]:
				attrs.isNative = (Span.range(_2, _3), Ident(sym, _4));
				rest = rest2;
			case [T(is_: var _2?), T(native: var _3?), ...var rest2]:
				attrs.isNative = (Span.range(_2, _3), null);
				rest = rest2;
			case [T(is_: var _2?), T(inline: var _3?), ...var rest2]:
				attrs.isInline = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(asm: var _3?), ...var rest2]:
				attrs.isAsm = Span.range(_2, _3);
				rest = rest2;
			case [T(is_: var _2?), T(macro: var _3?), ...var rest2]:
				attrs.isMacro = Span.range(_2, _3);
				rest = rest2;
			
			default: break loop;
		}

		final StmtBody? body; switch(parseBody(rest)) {
			case Success(s: (var made, var rest2)):
				rest = rest2;
				body = made;
			case Failure(): body = null;
			case var err: return err.fatalIfBad(rest).cast();
		}
		
		return Success(
			Operator(_1, attrs,
				typevars: typevars,
				symbol: Ident(sym, _2),
				spec: spec,
				ret: ret,
				body: body
			),
			rest
		);
	} else {
		return Failure(tokens, null);
	}
}


/* DEINITS */

Result<Deinit> parseDeinitDecl(Span _1, Tokens tokens) => switch(tokens) {
	[T(is_: var _2?), T(static: var _3?), ...var rest] => switch(parseBody(rest)) {
		Success(s: (var body, var rest2)) => Success(
			Deinit(_1, EmptyMethodAttrs()..isStatic = Span.range(_2, _3), body: body),
			rest2
		),
		var err => err.fatalIfBad(rest).cast()
	},
	_ => switch(parseBody(tokens)) {
		Success(s: (var body, var rest)) => Success(
			Deinit(_1, EmptyMethodAttrs(), body: body),
			rest
		),
		var err => err.fatalIfBad(tokens).cast()
	}
};


/* TYPES */

Result<(Span, List<Type>)> parseTypeParents(Tokens tokens, [bool allowEOL = false]) {
	switch(tokens) {
		case [T(of: var _1?), ...var rest]: switch(parseType(rest)) {
			case Success(s: (var type, var rest2)):
				final parents = [type];

				loop: while(true) {
					if(rest2 case [T(k: K.comma), ...var rest3]) {
						switch(parseType(rest3)) {
							case Success(s: (var made, var rest4)):
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
		Success(s: (var params, var rest2)) => Success((Ident(name, span), params), rest2),
		Failure() => Success((Ident(name, span), null), rest),
		var err => err.cast()
	},
	_ => Failure(tokens, null)
};

Result<TypeSpec> parseTypeSpec(Tokens tokens) {
	switch(tokens) {
		case [T(hashLBracket: var begin?), ...var rest]:
			final types = <Type>[];

			while(true) switch(parseType(rest)) {
				case Success(s: (var type, var rest2)):
					types.add(type);

					switch(rest2) {
						case [T(rbracket: var end?), ...var rest3]: return Success(ManyTypes(begin, types, end), rest3);
						case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
						case [T(isAnySep: true), ...var rest3]: rest = rest3;
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
	if(rest case [T(wildcard: var _1?), ...var rest2]) switch(parseTypeArgs(rest2)) {
		case Success(s: (var args, var rest3)):
			return allowSingleWildcard? Success(Type.blank(_1, args), rest3) : Failure(tokens, rest2);
		
		case Failure(): switch(rest2) {
			case [T(k: K.dot), ...var rest3 && [T(k: K.typename), ...]]:
				rest = rest3;
				leading = [_1];
			case [T(k: K.dot), T(k: K.wildcard), ...]:
				leading = [_1];
			default:
				return allowSingleWildcard? Success(Type.blank(_1), rest2) : Failure(tokens, null);
		}

		case var err: return err.cast();
	}
	
	if(leading != null) loop: while(true) switch(rest) {
		case [T(wildcard: var _1?), T(k: K.dot), ...var rest2]:
			leading.add(_1);
			rest = rest2;
		case [T(k: K.wildcard), ...]: return Failure(tokens, rest);
		default: break loop;
	}

	return switch(parseTypeSeg(rest)) {
		Success(s: (var first, var rest2)) => switch(rest2) {
			[T(k: K.dot), T(k: K.typename), ...] => switch(parseTypeSegs(rest2)) {
				Success(s: (var segs, var rest3)) => Success(Type.path(segs..insert(0, first), leading), rest3),
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
		Success(s: (var args, var rest2)) => Success(TypeSeg(Ident(name, _1), args), rest2),
		Failure() => Success(TypeSeg(Ident(name, _1)), rest),
		var err => err.cast()
	},
	_ => Failure(tokens, null)
};

Result<List<TypeSeg>> parseTypeSegs(Tokens tokens) => switch(tokens) {
	[T(k: K.dot), ...var rest] => switch(parseTypeSeg(rest)) {
		Success(s: (var seg, var rest2)) => switch(parseTypeSegs(rest2)) {
			Success(s: (var segs, var rest3)) => Success(segs..insert(0, seg), rest3),
			Failure() => Success([seg], rest2),
			var err => err
		},
		var err => err.cast()
	},
	_ => Failure(tokens, null)
};

Result<Delims<List<Type>>> parseTypeArgs(Tokens tokens) {
	switch(tokens) {
		case [T(lbracket: var begin?), ...var rest]:
			final types = <Type>[];

			while(true) switch(parseType(rest)) {
				case Success(s: (var type, var rest2)):
					types.add(type);

					switch(rest2) {
						case [T(rbracket: var end?), ...var rest3]: return Success(Delims(begin, types, end), rest3);
						case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
						case [T(k: K.name || K.label || K.punned), ...] when types.length == 1: return Failure(tokens, rest2);
						case [T(isAnySep: true), ...var rest3]: rest = rest3;
						default: return Fatal(tokens, rest2);
					}
				
				case var err: return err.cast();
			}

		default: return Failure(tokens, null);
	}
}

Result<Type> parseTypeAnno(Tokens tokens, [bool allowSingleWildcard = false]) => switch(tokens) {
	[T(k: K.lparen)] => EndOfInput(tokens),
	[T(k: K.lparen), ...var rest] => switch(parseType(rest, allowSingleWildcard)) {
		Success(s: (var type, [T(k: K.rparen), ...var rest2])) => Success(type, rest2),
		Success(rest: []) => EndOfInput(tokens),
		Success(rest: var rest2) => Fatal(tokens, rest2),
		var err => err
	},
	_ => Failure(tokens, null)
};


/* STATEMENTS */

Result<StmtBody> parseBody(Tokens tokens) => switch(tokens) {
	[T(eqGt: var _1?), ...var rest] => switch(parseStmt(rest)) {
		Success(s: (var stmt, var rest2)) => Success(StmtBody.stmt(_1, stmt), rest2),
		var err => err.fatalIfFailed().cast()
	},
	_ => switch(parseBlock(tokens)) {
		Success(s: (var block, var rest)) => Success(StmtBody.block(block), rest),
		var err => err.cast()
	}
};

Result<Block> parseBlock(Tokens tokens) {
	switch(tokens) {
		case [T(lbrace: var begin?), T(rbrace: var end?), ...var rest]:
			return Success(Block(begin, [], end), rest);
		
		case [T(lbrace: var begin?), ...var rest]:
			final stmts = <Stmt>[];

			while(true) switch(parseStmt(rest)) {
				case Success(s: (var stmt, var rest2)):
					stmts.add(stmt);

					switch(rest2) {
						case [T(rbrace: var end?), ...var rest3]: return Success(Block(begin, stmts, end), rest3);
						case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
						case [(T(isAnySep: true)), ...var rest3]: rest = rest3;
						default: return Fatal(rest, rest2);
					}
				
				case var err: return err.fatalIfBad(rest).cast();
			}
		
		default: return Failure(tokens, null);
	}
}


Result<Stmt> parseStmt(Tokens tokens) {
	switch(tokens) {
		case [T(if_: var _1?), ...var rest]: return switch(parseExpr(rest)) {
			Success(s: (var cond, var rest2)) => switch(parseThenStmt(rest2)) {
				Success(s: (ThenBlock then, [T(else_: var _2?), ...var rest3])) => switch(parseBlock(rest3)) {
					Success(s: (var elseBlk, var rest4)) => Success(Stmt.ifElse(_1, reparseExpr(cond), then, (_2, elseBlk)), rest4),
					var err => err.cast()
				},
				Success(s: (var then, var rest3)) => Success(Stmt.ifElse(_1, reparseExpr(cond), then, null), rest3),
				var err => err.cast()
			},
			var err => err.cast()
		};

		case [T(case_: var _1?), T(lbrace: var begin?), ...var rest]:
			final cases = <CaseAt>[];

			while(true) switch(rest) {
				case [T(at: var _2?), ...var rest2]: switch(parseCaseAtStmt(_2, rest2)) {
					case Success(s: (var case_, var rest3)):
						cases.add(case_);

						switch(rest3) {
							case [T(k: K.rbrace), ...var rest4]: return Success(Stmt.cases(_1.union(begin), cases, null), rest4);
							case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
							case [T(isAnySep: true), ...var rest4]: rest = rest4;
							default: return Fatal(tokens, rest3);
						}
					
					case var err: return err.fatalIfFailed().cast();
				}
				case [T(else_: var _2?), ...var rest2]: return switch(parseThenStmt(rest2)) {
					Success(s: (var then, [T(k: K.rbrace), ...var rest3])) => Success(Stmt.cases(_1.union(begin), cases, (_2, then)), rest3),
					Success(rest: var rest3) => Fatal(tokens, rest3),
					var err => err.fatalIfFailed().cast()
				};
				case [T(k: K.rbrace), ...var rest2]: return Success(Stmt.cases(_1.union(begin), cases, null), rest2);
				default: return Fatal(tokens, rest);
			}
		
		case [T(match: var _1?), ...var rest]: switch(parseExpr(rest)) {
			case Success(s: (var expr, [T(lbrace: var begin?), ...var rest2])):
				expr = reparseExpr(expr);

				final cases = <PatternAt>[];

				while(true) switch(rest2) {
					case [T(at: var _2?), ...var rest3]: switch(parseMatchAtStmt(_2, rest3)) {
						case Success(s: (var case_, var rest4)):
							cases.add(case_);

							switch(rest4) {
								case [T(k: K.rbrace), ...var rest5]: return Success(Stmt.match(_1.union(begin), expr, cases, null), rest5);
								case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
								case [T(isAnySep: true), ...var rest5]: rest2 = rest5;
								default: return Fatal(tokens, rest4);
							}
						
						case var err: return err.fatalIfFailed().cast();
					}
					case [T(else_: var _2?), ...var rest3]: return switch(parseThenStmt(rest3)) {
						Success(s: (var then, [T(k: K.rbrace), ...var rest4])) => Success(Stmt.match(_1.union(begin), expr, cases, (_2, then)), rest4),
						Success(rest: var rest4) => Fatal(tokens, rest4),
						var err => err.fatalIfFailed().cast()
					};
					case [T(k: K.rbrace), ...var rest3]: return Success(Stmt.match(_1.union(begin), expr, cases, null), rest3);
					default: return Fatal(tokens, rest2);
				}
			
			case Success(s: (var expr, [T(at: var _2?), ...var rest2])):
				expr = reparseExpr(expr);
				switch(parseExpr(rest2)) {
					case Success(s: (var pattern, var rest3)): // TODO: should patterns be reparsed?
						final (Span, Expr)? cond; switch(parseAtIf(rest3)) {
							case Success(s: (var made, var rest4)):
								rest3 = rest4;
								cond = made;
							case var err: return err.cast();
						}

						return switch(parseThenStmt(rest3)) {
							Success(s: (ThenBlock then, [T(else_: var _3?), ...var rest4])) => switch(parseBlock(rest4)) {
								Success(s: (var elseBlk, var rest5)) => Success(Stmt.matchAt(_1, expr, (_2, pattern), cond, then, (_3, elseBlk)), rest5),
								var err => err.fatalIfFailed().cast()
							},
							Success(s: (var then, var rest4)) => Success(Stmt.matchAt(_1, expr, (_2, pattern), cond, then, null), rest4),
							var err => err.fatalIfFailed().cast()
						};
					
					case var err: return err.fatalIfFailed().cast();
				}
			
			case Success(rest: var rest2): return Fatal(tokens, rest2);
			case var err: return err.fatalIfFailed().cast();
		}

		case [T(while_: var _1?), ...var rest]: switch(parseExpr(rest)) {
			case Success(s: (var cond, var rest)):
				cond = reparseExpr(cond);
				var (label, rest2) = parseStmtLabel(rest);
				rest = rest2;
				return switch(parseThenStmt(rest)) {
					Success(s: (var body, var rest2)) => Success(Stmt.whileLoop(_1, cond, label, body), rest2),
					var err => err.fatalIfFailed().cast()
				};
			
			case var err: return err.fatalIfFailed().cast();
		}

		case [T(do_: var _1?), ...var rest]:
			var (label, rest2) = parseStmtLabel(rest);
			rest = rest2;
			return switch(parseBlock(rest)) {
				Success(s: (var body, [T(while_: var _2?), ...var rest2])) => switch(parseExpr(rest2)) {
					Success(s: (var cond, var rest3)) => Success(Stmt.doWhile(_1, label, body, _2, cond), rest3),
					var err => err.fatalIfFailed().cast()
				},
				Success(s: (var body, var rest2)) => Success(Stmt.doBlock(_1, label, body), rest2),
				var err => err.fatalIfFailed().cast()
			};
		
		case [T(for_: var _1?), ...var rest]: return switch(parseExpr(rest)) {
			Success(s: (var lvar, var rest2)) => switch(rest2.firstOrNull) {
				TLabel(n: (var startSpan, "from")) => parseLoopRange(_1, lvar, (startSpan, LoopStart.from), rest2.sublist(1)),
				TLabel(n: (var startSpan, "after")) => parseLoopRange(_1, lvar, (startSpan, LoopStart.after), rest2.sublist(1)),
				T(k: K.comma) => switch(parseExpr(rest2.sublist(1))) {
					Success(s: (var lvar2, var rest3)) => parseLoopIn(_1, lvar, lvar2, rest3),
					var err => err.fatalIfFailed().cast()
				},
				_ => parseLoopIn(_1, lvar, null, tokens)
			},
			var err => err.fatalIfFailed().cast()
		};

		case [T(recurse: var _1?), ...var rest]: switch(parseExpr(rest)) {
			case Success(s: (var lvar1, var rest2)):
				final lvars = [lvar1];
				while(true) if(rest2 case [T(comma: _?), ...var rest3]) {
					switch(parseExpr(rest3)) {
						case Success(s: (var lvar, var rest4)):
							lvars.add(lvar);
							rest2 = rest4;
						case var err: return err.fatalIfFailed().cast();
					}
				} else {
					break;
				}

				var (label, rest3) = parseStmtLabel(rest2);
				rest2 = rest3;

				return switch(parseThenStmt(rest2)) {
					Success(s: (var body, var rest2)) => Success(Stmt.recurse(_1, lvars, label, body), rest2),
					var err => err.fatalIfFailed().cast()
				};
			
			case var err: return err.fatalIfFailed().cast();
		}

		case [T(return_: var _1?), ...var rest]: return switch(parseFullExpr(rest)) {
			Success(s: (var expr, var rest2)) => Success(Stmt.returnStmt(_1, expr), rest2),
			Failure() => Success(Stmt.returnStmt(_1, null), rest),
			var err => err.cast()
		};

		case [T(break_: var _1?), TLitsym(n: (var _2, var label)), ...var rest]:
			return Success(Stmt.breakStmt(_1, Ident(label, _2)), rest);
		case [T(break_: var _1?), ...var rest]:
			return Success(Stmt.breakStmt(_1, null), rest);
		
		case [T(next: var _1?), ...var rest]:
			final label = switch(rest.firstOrNull) {
				TLitsym(n: (var _2, var sym)) => Ident(sym, _2),
				_ => null
			};
			if(label != null) [_, ...rest] = rest;
			
			if(rest case [TLabel(n: (var _3, "with")), ...var rest2]) {
				if(parseExpr(rest2) case Success(s: (var e1, var rest3))) {
					final exprs = [e1];
					while(true) if(rest3.firstOrNull case T(k: K.comma)) {
						switch(parseExpr(rest3.sublist(1))) {
							case Success(s: (var e, var rest4)):
								exprs.add(e);
								rest3 = rest4;
							case var err: return err.fatalIfFailed().cast();
						}
					} else {
						break;
					}
					return Success(Stmt.nextStmt(_1, label, exprs), rest3);
				} else {
					return FatalError(StarError.nextWithRequiresExpr(_1, _3));
				}
			} else {
				return Success(Stmt.nextStmt(_1, label, null), rest);
			}
		
		case [T(throw_: var _1?), ...var rest]: return switch(parseFullExpr(rest)) {
			Success(s: (var expr, var rest2)) => Success(Stmt.throwStmt(_1, expr), rest2),
			Failure() => Success(Stmt.throwStmt(_1, null), rest),
			var err => err.cast()
		};

		case [T(try_: var _1?), ...var rest]: switch(parseBlock(rest)) {
			case Success(s: (var block, [T(k: K.catch_), T(lbrace: var begin?), ...var rest2])):
				final cases = <PatternAt>[];

				while(true) switch(rest2) {
					case [T(at: var _2?), ...var rest3]: switch(parseMatchAtStmt(_2, rest3)) {
						case Success(s: (var case_, var rest4)):
							cases.add(case_);

							switch(rest4) {
								case [T(k: K.rbrace), ...var rest5]: return Success(Stmt.tryCatch(_1, block, begin, cases, null), rest5);
								case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
								case [T(isAnySep: true), ...var rest5]: rest2 = rest5;
								default: return Fatal(tokens, rest4);
							}

						case var err: return err.fatalIfFailed().cast();
					}

					case [T(else_: var _2?), ...var rest3]: return switch(parseThenStmt(rest3)) {
						Success(s: (var then, [T(k: K.rbrace), ...var rest4])) => Success(Stmt.tryCatch(_1, block, begin, cases, (_2, then)), rest4),
						Success(rest: var rest4) => Fatal(tokens, rest4),
						var err => err.fatalIfFailed().cast()
					};

					case [T(k: K.rbrace), ...var rest3]: return Success(Stmt.tryCatch(_1, block, begin, cases, null), rest3);

					default: return Fatal(tokens, rest2);
				}
			
			case Success(rest: [T(k: K.catch_), ...var rest2] || var rest2): return Fatal(tokens, rest2);
			case var err: return err.fatalIfFailed().cast();
		}

		case []: return EndOfInput(tokens);

		default: return switch(parseFullExpr(tokens)) {
			Success(s: (var expr, var rest)) => Success(Stmt.expr(reparseExpr(expr)), rest),
			var err => err.fatalIfFailed().cast()
		};
	}
}


Result<Then> parseThenStmt(Tokens tokens) => switch(tokens) {
	[T(eqGt: var _1?), ...var rest] => switch(parseStmt(rest)) {
		Success(s: (var stmt, var rest2)) => Success(Then.stmt(_1, stmt), rest2),
		var err => err.fatalIfFailed().cast()
	},
	_ => switch(parseBlock(tokens)) {
		Success(s: (var block, var rest)) => Success(Then.block(block), rest),
		var err => err.fatalIfBad(tokens).cast()
	}
};

Result<CaseAt> parseCaseAtStmt(Span _1, Tokens tokens) => switch(parseExpr(tokens)) {
	Success(s: (var cond, var rest)) => switch(parseThenStmt(rest)) {
		Success(s: (var then, var rest2)) => Success((span: _1, cond: reparseExpr(cond), then: then), rest2),
		var err => err.fatalIfFailed().cast()
	},
	var err => err.fatalIfFailed().cast()
};

Result<PatternAt> parseMatchAtStmt(Span _1, Tokens tokens) => switch(parseExpr(tokens)) {
	Success(s: (
		var pattern,
		[T(if_: var _2?), ...var rest] ||
		[T(k: K.lsep), T(if_: var _2?), ...var rest]
	)) => switch(parseExpr(rest)) {
		Success(s: (var cond, var rest2)) => switch(parseThenStmt(rest2)) {
			Success(s: (var then, var rest3)) => Success((span: _1, pattern: pattern, cond: (_2, reparseExpr(cond)), then: then), rest3),
			var err => err.fatalIfFailed().cast()
		},
		var err => err.fatalIfFailed().cast()
	},
	Success(s: (var pattern, var rest)) => switch(parseThenStmt(rest)) {
		Success(s: (var then, var rest2)) => Success((span: _1, pattern: pattern, cond: null, then: then), rest2),
		var err => err.fatalIfFailed().cast()
	},
	var err => err.fatalIfFailed().cast()
};

((Span, Ident)?, Tokens) parseStmtLabel(Tokens tokens) => switch(tokens) {
	[TLabel(n: (var _1, "label")), TLitsym(span: var _2, :var name), ...var rest] => ((_1, Ident(name, _2)), rest),
	_ => (null, tokens)
};

Result<(Span, Expr)?> parseWhileLabel(Tokens tokens) => switch(tokens) {
	[TLabel(n: (var _1, "while")), ...var rest] => switch(parseExpr(rest)) {
		Success(s: (var expr, var rest2)) => Success((_1, reparseExpr(expr)), rest2),
		var err => err.fatalIfFailed().cast()
	},
	_ => Success(null, tokens)
};

Result<(Span, Expr)?> parseAtIf(Tokens tokens) => switch(tokens) {
	[T(if_: var _1?), ...var rest] => switch(parseExpr(rest)) {
		Success(s: (var expr, var rest2)) => Success((_1, reparseExpr(expr)), rest2),
		var err => err.fatalIfFailed().cast()
	},
	_ => Success(null, tokens)
};

Result<Stmt> parseLoopIn(Span _1, Expr lvar, Expr? lvar2, Tokens tokens) {
	if(tokens case [TLabel(n: (var inSpan, "in")), ...var rest]) {
		switch(parseExpr(rest)) {
			case Success(s: (var inExpr, var rest2)):
				inExpr = reparseExpr(inExpr);

				final (Span, Expr)? cond; switch(parseWhileLabel(rest2)) {
					case Success(s: (var made, var rest3)):
						rest2 = rest3;
						cond = made;
					case var err: return err.cast();
				}

				final (label, rest3) = parseStmtLabel(rest2);
				rest2 = rest3;

				return switch(parseThenStmt(rest2)) {
					Success(s: (var body, var rest3)) => Success(
						Stmt.forIn(_1, lvar, lvar2, (inSpan, inExpr), cond, label, body),
						rest3
					),
					var err => err.fatalIfFailed().cast()
				};
			
			case var err: return err.fatalIfFailed().cast();
		}
	} else {
		return Fatal(tokens, null);
	}
}

Result<Stmt> parseLoopRange(Span _1, Expr lvar, (Span, LoopStart) start, Tokens tokens) {
	switch(parseExpr(tokens)) {
		case Success(s: (var startExpr, var rest)):
			startExpr = reparseExpr(startExpr);

			final (Span, LoopStop) stop; if(rest case [TLabel(n: (var _2, var label)), ...var rest2]) {
				switch(label) {
					case "to": stop = (_2, LoopStop.to);
					case "upto": stop = (_2, LoopStop.upto);
					case "downto": stop = (_2, LoopStop.downto);
					case "times": stop = (_2, LoopStop.times);
					default: return Fatal(tokens, rest);
				}
				rest = rest2;
			} else {
				return Fatal(tokens, rest);
			}

			switch(parseExpr(rest)) {
				case Success(s: (var stopExpr, var rest2)):
					stopExpr = reparseExpr(stopExpr);

					(Span, Expr)? step; if(rest2 case [TLabel(n: (var _2, "by")), ...var rest3]) {
						switch(parseExpr(rest3)) {
							case Success(s: (var expr, var rest4)):
								expr = reparseExpr(expr);
								rest2 = rest4;
								step = (_2, expr);
							case var err: return err.fatalIfFailed().cast();
						}
					} else {
						step = null;
					}

					final (Span, Expr)? cond; switch(parseWhileLabel(rest2)) {
						case Success(s: (var made, var rest3)):
							rest2 = rest3;
							cond = made;
						case var err: return err.cast();
					}

					final (label, rest3) = parseStmtLabel(rest2);
					rest2 = rest3;

					return switch(parseThenStmt(rest2)) {
						Success(s: (var body, var rest3)) => Success(
							Stmt.forRange(_1, lvar, (start.$1, start.$2, startExpr), (stop.$1, stop.$2, stopExpr), step, cond, label, body),
							rest3
						),
						var err => err.fatalIfFailed().cast()
					};
				
				case var err: return err.fatalIfFailed().cast();
			}
		
		case var err: return err.fatalIfFailed().cast();
	}
}


/* EXPRESSIONS */

// ...

Result<Expr> parseBasicExpr(Tokens tokens) => switch(tokens) {
	[T(asSoftName: TName(n: (var _1, var name))), ...var rest] => Success(Expr.name(Ident(name, _1)), rest),
	[TLitsym(n: (var _1, var sym)), ...var rest] => Success(Expr.litsym(Ident(sym, _1)), rest),
	[TInt(span: var _1, :var i), ...var rest] => Success(Expr.int(_1, i), rest),
	[THex(span: var _1, :var h), ...var rest] => Success(Expr.int(_1, h), rest),
	[TDec(span: var _1, :var d), ...var rest] => Success(Expr.dec(_1, d), rest),
	[TStr(span: var _1, :var segs), ...var rest] => switch(parseStrSegs(segs)) {
		Success(made: var parts) => Success(Expr.str(_1, parts), rest),
		var err => err.cast()
	},
	[TChar(span: var _1, :var c), ...var rest] => Success(Expr.char(_1, c), rest),
	[TBool(span: var _1, :var b), ...var rest] => Success(Expr.bool(_1, b), rest),
	[T(this_: var _1?), ...var rest] => Success(Expr.this_kw(_1), rest),
	[TAnonArg(span: var _1, :var depth, :var nth), ...var rest] => Success(Expr.anonArg(_1, depth, nth), rest),
	[T(k: K.typename || K.wildcard), ...var rest] => switch(parseType(tokens)) {
		Success(s: (var type, var rest2)) => Success(Expr.type(type), rest2),
		Failure f => switch(tokens[0]) {
			T(wildcard: var _1?) => Success(Expr.wildcard(_1), rest),
			_ => f.cast()
		},
		var err => err.cast()
	},
	[T(hashLBracket: var begin?), T(hashLBracket: var end?), ...var rest] => Success(Expr.array(begin, [], end), rest),
	[T(hashLBracket: var begin?), ...var rest] => switch(parseArrayContents(rest)) {
		Success(s: ((var exprs, var end), var rest2)) => Success(Expr.array(begin, exprs, end), rest2),
		var err => err.cast()
	},
	[T(hashLParen: var begin?), T(hashLParen: var end?), ...var rest] => Success(Expr.array(begin, [], end), rest),
	[T(hashLParen: var begin?), ...var rest] => switch(parseDictContents(rest)) {
		Success(s: ((var pairs, var end), var rest2)) => Success(Expr.dict(begin, pairs, end), rest2),
		var err => err.cast()
	},
	[T(hashLBrace: var begin?), T(hashLBrace: var end?), ...var rest] => Success(Expr.array(begin, [], end), rest),
	[T(hashLBrace: var begin?), ...var rest] => switch(parseTupleContents(rest)) {
		Success(s: ((var exprs, var end), var rest2)) => Success(Expr.tuple(begin, exprs, end), rest2),
		var err => err.cast()
	},
	[T(lparen: var begin?), ...var rest] => switch(parseParenContents(rest)) {
		Success(s: ((var exprs, var end), var rest2)) => Success(Expr.paren(begin, exprs, end), rest2),
		var err => err.cast()
	},
	[T(lbracket: var begin?), ...var rest] => switch(parseFullExpr(rest)) {
		Success(s: (EType(:var type), [T(lsep: _?), ...var rest2] || var rest2)) => switch(finishTypeMsg(rest2)) {
			Success(s: ((var msg, var end), var rest3)) => Success(Expr.typeMsg(type, begin, msg, end), rest3),
			var err => err.fatalIfFailed().cast()
		},
		Success(s: (var expr, [T(lsep: _?), ...var rest2] || var rest2)) => switch(finishExprMsg(rest2)) {
			Success(s: ((var msg, var end), var rest3)) => Success(Expr.exprMsg(expr, begin, msg, end), rest3),
			var err => err.fatalIfFailed().cast()
		},
		var err => err.fatalIfFailed().cast()
	},
	[T(lbrace: var begin?), T(barBar: _?), ...var rest] ||
	[T(lbrace: var begin?), T(bar: _?), T(bar: _?), ...var rest] => finishFunc(begin, [], rest),
	[T(lbrace: var begin?), T(bar: _?), ...var rest] => finishFuncArgs(begin, rest),
	[T(lbrace: var _?), ...] => switch(parseBlock(tokens)) {
		Success(s: (var block, var rest)) => Success(Expr.block(block), rest),
		var err => err.fatalIfFailed().cast()
	},
	[T(my: var _1?), ...var rest] => switch(rest) {
		[T(asSoftName: TName(n: (var _2, var name))), ...var rest] => (){
			Type? type; switch(parseTypeAnno(rest)) {
				case Success(s: (var t, var rest2)):
					rest = rest2;
					type = t;
				case Failure():
					type = null;
				case var err: return err.cast<Expr>();
			}

			Expr? expr; if(rest case [T(eq: _?), ...var rest2]) {
				switch(parseFullExpr(rest2)) {
					case Success(s: (var e, var rest3)):
						rest = rest3;
						expr = e;
					case var err: return err;
				}
			} else {
				expr = null;
			}

			return Success(Expr.varDecl(_1, Ident(name, _2), type, expr), rest);
		}(),
		_ => Fatal(tokens, null)
	},
	_ => Failure(tokens, null)
};

Result<(List<Expr> exprs, Span end)> parseArrayContents(Tokens tokens) {
	final exprs = <Expr>[];
	var rest = tokens;
	
	while(true) switch(parseFullExpr(rest)) {
		case Success(s: (var e, var rest2)):
			exprs.add(e);

			switch(rest2) {
				case [T(rbracket: var end?), ...var rest3]: return Success((exprs, end), rest3);
				case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
				case [T(isAnySep: true), ...var rest3]: rest = rest3;
				default: return Fatal(tokens, rest2);
			}

		case var err: return err.cast();
	}
}

Result<(List<(Expr, Expr)> pairs, Span end)> parseDictContents(Tokens tokens) {
	final pairs = <(Expr, Expr)>[];
	var rest = tokens;
	
	while(true) switch(parseFullExpr(rest)) {
		case Success(s: (var k, [T(eqGt: _?), ...var rest2])):
			switch(parseFullExpr(rest2)) {
				case Success(s: (var v, var rest3)):
					pairs.add((k, v));

					switch(rest3) {
						case [T(rbracket: var end?), ...var rest4]: return Success((pairs, end), rest4);
						case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
						case [T(isAnySep: true), ...var rest4]: rest = rest4;
						default: return Fatal(tokens, rest3);
					}
				
				case var err: return err.cast();
			}

		case Success(s: (_, var rest2)): return Fatal(tokens, rest2);
		case var err: return err.cast();
	}
}

Result<(List<Expr> exprs, Span end)> parseTupleContents(Tokens tokens) {
	final exprs = <Expr>[];
	var rest = tokens;
	
	while(true) switch(parseFullExpr(rest)) {
		case Success(s: (var e, var rest2)):
			exprs.add(e);

			switch(rest2) {
				case [T(rbrace: var end?), ...var rest3]: return Success((exprs, end), rest3);
				case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
				case [T(isAnySep: true), ...var rest3]: rest = rest3;
				default: return Fatal(tokens, rest2);
			}

		case var err: return err.cast();
	}
}

Result<(List<Expr> exprs, Span end)> parseParenContents(Tokens tokens) {
	final exprs = <Expr>[];
	var rest = tokens;

	if(!removeNewlines(tokens)) {
		throw EndOfInput(tokens);
	}

	InfixOp? leadingOp = switch(tokens.first.k) {
		K.andAnd => InfixOp.and,
		K.barBar => InfixOp.or,
		K.caretCaret => InfixOp.xor,
		K.bangBang => InfixOp.nor,
		_ => null
	};
	if(leadingOp != null) [_, ...rest] = rest;

	while(true) switch(parseFullExpr(rest)) {
		case Success(s: (var e, var rest2)):
			exprs.add(e);

			switch(rest2.firstOrNull) {
				case T(rparen: var end?):
					[_, ...rest2] = rest2;

					if(leadingOp != null) {
						var e0 = exprs[0];
						if(!(e0 is EInfix && e0.op == leadingOp)) {
							return Fatal(tokens, null);
						}
					}

					return Success((exprs, end), rest2);
				
				case T(isAnyComma: true):
					if(rest2.length == 1) return EndOfInput(tokens);
					else [_, ...rest] = rest2;
				
				case null: return EndOfInput(tokens);
				default: return Fatal(tokens, rest2);
			}
		
		case var err: return err.cast();
	}
}

bool removeNewlines(Tokens tokens) {
	var i = 0;
	while(i < tokens.length) switch(tokens.sublist(i)) {
		case [T(k: K.lparen || K.hashLParen), ...]:
			i = skipParens(tokens, i + 1);
			if(tokens[i].k == K.lsep) {
				tokens.removeAt(i);
			}
		case [T(k: K.lbracket || K.hashLBracket), ...]: i = skipBrackets(tokens, i + 1);
		case [T(k: K.lbrace || K.hashLBrace), ...]: i = skipBraces(tokens, i + 1);
		case [T(k: K.rparen), ...]: return true;
		case [_, T(k: K.lsep), T(k: K.cascade), ...]: i += 3;
		case [_, T(k: K.lsep), ...]:
			tokens.removeAt(i + 1);
			i += 1;
		case [_, ...]: i += 1;
		case []: return false;
	}

	throw "Error!";
}

int skipParens(Tokens tokens, int i) {
	while(i < tokens.length) switch(tokens.sublist(i)) {
		case [T(k: K.lparen || K.hashLParen), ...]: i = skipParens(tokens, i + 1);
		case [T(k: K.lbracket || K.hashLBracket), ...]: i = skipBrackets(tokens, i + 1);
		case [T(k: K.lbrace || K.hashLBrace), ...]: i = skipBraces(tokens, i + 1);
		case [T(k: K.rparen), ...]: return i + 1;
		case [_, T(k: K.lsep), T(k: K.cascade), ...]: i += 3;
		case [_, T(k: K.lsep), ...]:
			tokens.removeAt(i + 1);
			i += 1;
		case [_, ...]: i += 1;
		case []: throw "Error!";
	}

	return i;
}

int skipBrackets(Tokens tokens, int i) {
	while(i < tokens.length) switch(tokens.sublist(i)) {
		case [T(k: K.lparen || K.hashLParen), ...]: i = skipParens(tokens, i + 1);
		case [T(k: K.lbracket || K.hashLBracket), ...]: i = skipBrackets(tokens, i + 1);
		case [T(k: K.lbrace || K.hashLBrace), ...]: i = skipBraces(tokens, i + 1);
		case [T(k: K.rbracket), ...]: return i + 1;
		case [_, T(k: K.lsep), T(k: K.cascade), ...]: i += 3;
		case [_, T(k: K.lsep), ...]:
			tokens.removeAt(i + 1);
			i += 1;
		case [_, ...]: i += 1;
		case []: throw "Error!";
	}

	return i;
}

int skipBraces(Tokens tokens, int i) {
	while(i < tokens.length) switch(tokens.sublist(i)) {
		case [T(k: K.lparen || K.hashLParen), ...]: i = skipParens(tokens, i + 1);
		case [T(k: K.lbracket || K.hashLBracket), ...]: i = skipBrackets(tokens, i + 1);
		case [T(k: K.lbrace || K.hashLBrace), ...]: i = skipBraces(tokens, i + 1);
		case [T(k: K.rbrace), ...]: return i + 1;
		case [_, T(k: K.lsep), T(k: K.cascade), ...]: i += 3;
		case [_, T(k: K.lsep), ...]:
			tokens.removeAt(i + 1);
			i += 1;
		case [_, ...]: i += 1;
		case []: throw "Error!";
	}

	return i;
}


Result<List<StrPart>> parseStrSegs(List<StrSegment> segs) => throw "";

Result<Expr> parseExpr(Tokens tokens) => parseBasicExpr(tokens);

Result<Expr> parseFullExpr(Tokens tokens) => parseExpr(tokens);

Result<(Message<Type> msg, Span end)> finishTypeMsg(Tokens tokens) => throw "";
Result<(Message<Expr> msg, Span end)> finishExprMsg(Tokens tokens) => throw "";

Result<Expr> finishFuncArgs(Span begin, Tokens tokens) {
	final params = <(Ident name, Type? type)>[];
	var rest = tokens;

	while(true) {
		if(rest case [T(asSoftName: TName(n: (var _1, var name))), ...var rest2]) {
			if(rest2 case [T(lparen: _?), ...]) {
				switch(parseTypeAnno(rest2)) {
					case Success(s: (var type, var rest3)):
						rest = rest3;
						params.add((Ident(name, _1), type));
					case var err:
						return err.fatalIfFailed().cast();
				}
			} else {
				rest = rest2;
				params.add((Ident(name, _1), null));
			}
		} else {
			return Fatal(tokens, rest);
		}

		if(rest.firstOrNull?.k == K.bar) {
			[_, ...rest] = rest;
			break;
		} else if(rest.firstOrNull?.k == K.comma) {
			[_, ...rest] = rest;
		} else {
			return Fatal(tokens, rest);
		}
	}

	return finishFunc(begin, params, rest);
}
Result<Expr> finishFunc(Span begin, List<(Ident name, Type? type)> params, Tokens tokens) => switch(parseTypeAnno(tokens)) {
	Success(s: (var ret, [T(rbrace: var end?), ...var rest])) => Success(Expr.func(begin, params, ret, [], end), rest),
	Success(s: (var ret, [T(lsep: _?), ...var rest] || var rest)) => finishFuncBody(begin, params, ret, rest),
	Failure() => finishFuncBody(begin, params, null, switch(tokens) {
		[T(lsep: _?), ...var rest] => rest,
		_ => tokens
	}),
	var err => err.cast()
};

Result<Expr> finishFuncBody(Span begin, List<(Ident name, Type? type)> params, Type? ret, Tokens tokens) {
	final stmts = <Stmt>[];
	var rest = tokens;

	while(true) switch(parseStmt(rest)) {
		case Success(s: (var stmt, var rest2)):
			stmts.add(stmt);
			
			switch(rest2) {
				case [T(rbrace: var end?), ...var rest3]: return Success(Expr.func(begin, params, ret, stmts, end), rest3);
				case [] || [T(isAnySep: true)]: return EndOfInput(tokens);
				case [T(isAnySep: true), ...var rest3]: rest = rest3;
				default: return Fatal(tokens, rest2);
			}
		
		case var err: return err.fatalIfBad(rest).cast();
	}
}

/* REPARSE */

Expr reparseExpr(Expr expr) => throw "";