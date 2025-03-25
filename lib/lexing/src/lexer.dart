// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'package:star/errors/errors.dart';
import 'token.dart';
import 'reader.dart';

final class Lexer {
	final Reader reader;
	final SourceFile source;
	var begin = Pos(0, 0);

	Lexer(this.source): reader = Reader(source.text);

	(List<Object>, List<Token>) tokenize() {
		final errors = <Object>[];
		final tokens = <Token>[];
		while(true) {
			try {
				while(reader.hasNext) tokens.add(readToken());
				break;
			} on Eof catch(_) {
				break;
			} catch (e) {
				print('$e ${e.runtimeType}');
				errors.add(e);
			}
		}

		retoken(tokens);

		return (errors, tokens);
	}

	static final keywords = { for(K k = K.module; k <= K.catch_; k++) k.name: k };
	static final attrs = { for(K k = K.static; k <= K.macro; k++) k.name: k };

	void retoken(Tokens tokens) {
		for(var i = 0; i < tokens.length; i++) {
			switch((tokens[i], tokens.elementAtOrNull(i+1))) {
				case (T_Token(k: >= K.lparen && <= K.hashLBrace), T_Token(k: K.lsep)):
					tokens.removeAt(i + 1);
				
				case (T_Token(k: K.lsep), T_Token(k: K.rparen || K.rbracket || K.rbrace)):
					tokens.removeAt(i);
				
				case (T_Token(k: K.dot), T_Name _):
					i++;
				
				case (T_Name(span: final span, name: "my"), T_Name _):
					tokens[i] = T_Token(K.my, span);
					i++;
				case (T_Name(span: final span, name: "has"), T_Name _):
					tokens[i] = T_Token(K.has, span);
					i++;
				
				case (T_Name(span: final span, name: "this"), _): tokens[i] = T_Token(K.this_, span);
				case (T_Name(span: final span, name: "true"), _): tokens[i] = T_Bool(span, true);
				case (T_Name(span: final span, name: "false"), _): tokens[i] = T_Bool(span, false);

				case (T_Name(span: final span1, name: "is"), T_Name(span: final span2, name: final attr)):
					if(attrs[attr] case final _attr?) {
						tokens[i] = T_Token(K.is_, span1);
						tokens[i + 1] = T_Token(_attr, span2);
						i++;
					}
				
				case (T_Name(span: final span, name: final kw), _):
					if(keywords[kw] case final _kw?) {
						tokens[i] = T_Token(_kw, span);
					}
				
				case (T_Str(segs: final segs), _):
					retokenStr(segs);
				
				case (T_Token(k: K.lsep), null):
					tokens.removeAt(i);
					return;

				default:
			}
		}
	}

	void retokenStr(List<StrSegment> segs) {
		for(final seg in segs) {
			if(seg is StrSeg_Code) {
				retoken(seg.tokens);
			}
		}
	}

	Pos get here => reader.cursor.pos;
	Span get span => Span(begin, here, source);

	void trim() {
		loop: while(reader.hasNext) switch(reader.unsafePeek()) {
			case Char.SPACE || Char.TAB: reader.next();
			case Char.SEMICOLON:
				reader.next();
				if(reader.peek() case _? && >= Char.LF && <= Char.CR) {
					break loop;
				} else {
					readComment();
				}
			default: break loop;
		}
	}

	void readComment() {
		if(reader.eatChar(Char.LBRACK)) {
			readNestedComment();
			if(reader.peek() case _? && >= Char.LF && <= Char.CR) {
				reader.next();
			}
		} else {
			while(reader.hasNext) {
				if(reader.unsafePeek() case >= Char.LF && <= Char.CR) {
					break;
				} else {
					reader.next();
				}
			}
		}
	}

	void readNestedComment() {
		while(reader.hasNext) switch(reader.eat()) {
			case Char.LBRACK: readNestedComment();
			case Char.RBRACK: return;
			default: continue;
		}

		throw StarError.unterminatedComment(Span.at(begin, source));
	}

	Token readToken() {
		final oldBegin = (begin = here);

		trim();
		
		if(!reader.hasNext) throw "eof";

		final cur = reader.unsafePeek();
		
		begin = here;

		switch(cur) {
			case >= Char.LF && <= Char.CR:
				begin = oldBegin;
				return readLSep();
			
			case Char.COMMA:
				reader.next();
				return readComma();
			
			case >= Char.ZERO && <= Char.NINE:
				return readNumberStart();
			
			case >= Char.a && <= Char.z:
				return readName();
			
			case Char.UNDERSCORE:
				switch(reader.unsafePeekAt(1)) {
					case (
						>= Char.a && <= Char.z ||
						>= Char.A && <= Char.Z ||
						>= Char.ZERO && <= Char.NINE
						|| Char.UNDERSCORE
						|| Char.SQUOTE
						|| Char.COLON
					):
						return readName();
					
					default:
						reader.next();
						return T_Token(K.wildcard, span);
				}
			
			case Char.COLON:
				reader.next();
				return readPunned();
			
			case >= Char.A && <= Char.Z:
				return readTypeName();
				
			case Char.DOT:
				reader.next();
				if(reader.eatChar(Char.DOT)) {
					if(reader.eatChar(Char.DOT)) {
						return T_Token(K.dotDotDot, span);
					} else {
						throw StarError.invalidOperator("..", span);
					}
				} else {
					return T_Token(K.dot, span);
				}
			
			case Char.LPAREN: reader.next(); return T_Token(K.lparen, span);
			case Char.RPAREN: reader.next(); return T_Token(K.rparen, span);
			case Char.LBRACK: reader.next(); return T_Token(K.lbracket, span);
			case Char.RBRACK: reader.next(); return T_Token(K.rbracket, span);
			case Char.LBRACE: reader.next(); return T_Token(K.lbrace, span);
			case Char.RBRACE: reader.next(); return T_Token(K.rbrace, span);
			case Char.TILDE: reader.next(); return T_Token(K.tilde, span);

			case Char.DQUOTE:
				reader.next();
				return reader.eatChar(Char.DQUOTE)? T_Str(span, []) : readStr();

			case Char.HASH:
				reader.next();
				switch(reader.unsafePeek()) {
					case >= Char.a && <= Char.z: return readTag();
					case Char.LPAREN: reader.next(); return T_Token(K.hashLParen, span);
					case Char.LBRACK: reader.next(); return T_Token(K.hashLBracket, span);
					case Char.LBRACE: reader.next(); return T_Token(K.hashLBrace, span);
					case Char.DQUOTE: reader.next(); return readChar();
					default:
						throw StarError.invalidInputAfterHash(
							reader.peek()!,
							Span.at(begin, source),
							Span.at(here, source)
						);
				}
			
			// =, =>
			case Char.EQ:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.GT: reader.next(); return T_Token(K.eqGt, span);
					case Char.EQ:
						reader.next();
						throw StarError.invalidEqEq(span);
					default: return T_Token(K.eq, span);
				}
			
			// ?, ?=
			case Char.QUESTION:
				reader.next();
				if(reader.eatChar(Char.EQ))
					return T_Token(K.questionEq, span);
				else
					return T_Token(K.question, span);
			

			// !, !=, !!, !!=
			case Char.BANG:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.bangEq, span); 
					case Char.BANG:
						reader.next();
						if(reader.eatChar(Char.EQ))
							return T_Token(K.bangBangEq, span);
						else
							return T_Token(K.bangBang, span);
					
					default: return T_Token(K.bang, span);
				}
			

			// +, +=, ++
			case Char.PLUS:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.plusEq, span); 
					case Char.PLUS: reader.next(); return T_Token(K.plusPlus, span); 
					default: return T_Token(K.plus, span);
				}
			
			// -, -=, --, ->
			case Char.MINUS:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.minusEq, span); 
					case Char.MINUS:
						reader.next();
						switch(reader.unsafePeek()) {
							case Char.MINUS:
								reader.next();
								
								var depth = 3;

								while(reader.eatChar(Char.MINUS)) depth++;

								if(reader.eatChar(Char.GT)) {
									return T_Cascade(span, depth: depth);
								} else {
									final end = here;
									throw StarError.unterminatedCascade(
										Span(begin, end, source),
										Span.at(end, source)
									);
								}
							
							case Char.GT: reader.next(); return T_Cascade(span, depth: 2); 
							default: return T_Token(K.minusMinus, span);
						}
					
					case Char.GT: reader.next(); return T_Cascade(span, depth: 1); 
					default: return T_Token(K.minus, span);
				}
			
			// *, *=, **, **=
			case Char.STAR:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.starEq, span); 
					case Char.STAR:
						reader.next();
						if(reader.eatChar(Char.EQ))
							return T_Token(K.starStarEq, span);
						else
							return T_Token(K.starStar, span);
					
					default: return T_Token(K.star, span);
				}
			

			// /, /=, //, //=
			case Char.FSLASH:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.divEq, span); 
					case Char.FSLASH:
						reader.next();
						if(reader.eatChar(Char.EQ))
							return T_Token(K.divDivEq, span);
						else
							return T_Token(K.divDiv, span);
					
					default: return T_Token(K.div, span);
				}
			

			// %, %=, %%, %%=
			case Char.PERCENT:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.modEq, span); 
					case Char.PERCENT:
						reader.next();
						if(reader.eatChar(Char.EQ))
							return T_Token(K.modModEq, span);
						else
							return T_Token(K.modMod, span);
					
					default: return T_Token(K.mod, span);
				}
			

			// &, &=, &&, &&=
			case Char.AND:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.andEq, span); 
					case Char.AND:
						reader.next();
						if(reader.eatChar(Char.EQ))
							return T_Token(K.andAndEq, span);
						else
							return T_Token(K.andAnd, span);
					
					default: return T_Token(K.and, span);
				}
			

			// |, |=, ||, ||=
			case Char.PIPE:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.barEq, span); 
					case Char.PIPE:
						reader.next();
						if(reader.eatChar(Char.EQ))
							return T_Token(K.barBarEq, span);
						else
							return T_Token(K.barBar, span);
					
					default: return T_Token(K.bar, span);
				}
			

			// ^, ^=, ^^, ^^=
			case Char.CARET:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.caretEq, span); 
					case Char.CARET:
						reader.next();
						if(reader.eatChar(Char.EQ))
							return T_Token(K.caretCaretEq, span);
						else
							return T_Token(K.caretCaret, span);
					
					default: return T_Token(K.caret, span);
				}
			

			// <, <=, <<, <<=
			case Char.LT:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.ltEq, span); 
					case Char.LT:
						reader.next();
						if(reader.eatChar(Char.EQ))
							return T_Token(K.ltLtEq, span);
						else
							return T_Token(K.ltLt, span);
					
					default: return T_Token(K.lt, span);
				}
			

			// >, >=, >>, >>=
			case Char.GT:
				reader.next();
				switch(reader.unsafePeek()) {
					case Char.EQ: reader.next(); return T_Token(K.gtEq, span); 
					case Char.GT:
						reader.next();
						if(reader.eatChar(Char.EQ))
							return T_Token(K.gtGtEq, span);
						else
							return T_Token(K.gtGt, span);
					
					default: return T_Token(K.gt, span);
				}
			
			case Char.BACKTICK:
				reader.next();
				return readLitsym();
			
			case Char.DOLLAR:
				reader.next();
				return readAnonArg();
			
			default:
				throw StarError.invalidInput(Span.at(begin, source));
		}
	}

	Token readLSep() {
		do {
			reader.next();
			trim();
		} while(reader.hasNext && switch(reader.unsafePeek()) {
			>= Char.LF && <= Char.CR => true,
			_ => false
		});

		return reader.eatChar(Char.COMMA)? readCSep() : T_Token(K.lsep, span);
	}

	Token readCSep() {
		trim();

		while(reader.hasNext && switch(reader.unsafePeek()) {
			>= Char.LF && <= Char.CR => true,
			_ => false
		}) {
			reader.next();
			trim();
		}

		return T_Token(K.csep, span);
	}

	Token readComma() {
		trim();
		
		if(reader.hasNext && switch(reader.unsafePeek()) {
			>= Char.LF && <= Char.CR => true,
			_ => false
		}) {
			reader.next();
			return readCSep();
		}

		return T_Token(K.comma, span);
	}

	Token readNumberStart() {
		if(reader.hasNextAt(2) && reader.unsafePeekAt(1) == Char.x && reader.unsafePeek() == Char.ZERO) {
			reader.next();
			reader.next();
			if(reader.peekHex()) {
				return readHex();
			} else {
				throw StarError.invalidHexStart(span);
			}
		} else {
			return readNumber();
		}
	}

	Token readHex() {
		final start = reader.offset;

		do reader.next(); while(reader.peekHex());

		if(reader.peekAlphaU()) {
			final end = here;

			while(reader.peekAlnumQ()) reader.next();

			final endName = here;

			throw StarError.nameAfterHex(
				Span(begin, end, source),
				Span(end, endName, source)
			);
		} else {
			return T_Hex(span, int.parse(reader.substring(start), radix: 16));
		}
	}

	Token readNumber() {
		var start = reader.offset;
		
		do reader.next(); while(reader.peekDigit());

		final int_ = reader.substring(start);
		final afterDigits = here;

		String? dec = null;
		if(reader.hasNextAt(1) && reader.unsafePeekChar(Char.DOT) && switch(reader.unsafePeekAt(1)) {
			>= Char.a && <= Char.z
			|| Char.UNDERSCORE => false,
			_ => true
		}) {
			reader.next();
			if(reader.peekDigit()) {
				start = reader.offset;

				do reader.next(); while(reader.peekDigit());

				dec = reader.substring(start);
			} else {
				final end = here;

				throw StarError.incompleteDecimalPoint(
					Span(begin, end.advance(-1), source),
					Span.at(afterDigits, source)
				);
			}
		}

		final exp = reader.eatChar(Char.e)? readExponent() : null;

		if(reader.peekAlphaU()) {
			final end = here;

			while(reader.peekAlnumQ()) reader.next();

			final endName = here;

			throw StarError.nameAfterNumber(
				Span(begin, end, source),
				Span(end, endName, source)
			);
		} else {
			if(dec == null && (exp == null || !exp.startsWith("-"))) {
				return T_Int(span, exp == null
									? int.parse(int_)
									: double.parse("${int_}e$exp").toInt());
			} else {
				return T_Dec(span, double.parse(exp == null? "$int_.$dec" : "$int_.${dec}e$exp"));
			}
		}
	}

	String readExponent() {
		final start = reader.offset;
		final ruleBegin = here;

		if(reader.unsafePeek() case Char.PLUS || Char.MINUS) {
			reader.next();
		}

		if(reader.peekDigit()) {
			do reader.next(); while(reader.peekDigit());

			return reader.substring(start);
		} else {
			final end = here;

			throw StarError.missingExponent(
				Span(ruleBegin.advance(-1), end, source),
				Span(end, end.advance(1), source)
			);
		}
	}

	Token readName() {
		final start = reader.offset;

		do reader.next(); while(reader.peekAlnumQ());

		final n = reader.substring(start);

		return reader.eatChar(Char.COLON)? T_Label(span, n) : T_Name(span, n);
	}

	Token readPunned() {
		final start = reader.offset;

		if(reader.peekLowerU()) {
			reader.next();
		} else {
			final end = here;

			if(reader.unsafePeek() case >= Char.A && <= Char.Z) {
				while(reader.peekAlnumQ()) reader.next();

				final endName = here;

				throw StarError.noUppercasePunnedLabel(
					Span.at(begin, source),
					Span.at(end, source),
					Span(end, endName, source)
				);
			} else {
				throw StarError.incompletePunnedLabel(
					Span.at(begin, source),
					Span.at(begin.advance(1), source)
				);
			}
		}

		while(reader.peekAlnumQ()) reader.next();

		return T_Punned(span, reader.substring(start));
	}

	Token readTypeName() {
		final start = reader.offset;

		do reader.next(); while(reader.peekAlnumQ());
		
		final n = reader.substring(start);

		if(reader.eatChar(Char.COLON)) {
			final end = here;

			throw StarError.noUppercaseLabel(
				Span.at(begin, source),
				Span(begin.advance(1), end, source)
			);
		} else {
			return T_Typename(span, n);
		}
	}

	Token readLitsym() {
		final start = reader.offset;

		while(reader.peekNotChar(Char.BACKTICK)) reader.next();
		
		final sym = reader.substring(start);

		reader.next();

		return T_Litsym(span, sym);
	}

	Token readTag() {
		final start = reader.offset;

		while(reader.peekAlnum()) reader.next();

		return T_Tag(span, reader.substring(start));
	}

	Token readChar() {
		late final Char char;
		switch(reader.unsafePeek()) {
			case Char.DQUOTE:
				final end = here;
				reader.next();
				if(reader.unsafePeek() == Char.DQUOTE) {
					reader.next();
					throw StarError.escapeCharQuote(
						Span(begin, end, source),
						Span.at(end, source),
						Span.at(end.advance(1), source)
					);
				} else {
					throw StarError.noEmptyChar(Span(begin, end, source));
				}

			case Char.BSLASH:
				reader.next();
				char = switch(reader.eat()) {
					final c && (Char.BSLASH || Char.DQUOTE) => c,
					Char.t => Char.TAB,
					Char.n => Char.LF,
					Char.r => Char.CR,
					Char.v => Char(0x0b),
					Char.f => Char(0x0c),
					Char.ZERO => Char(0x00),
					Char.e => Char(0x1b),
					Char.a => Char(0x07),
					Char.b => Char(0x08),
					Char.x => readHexEsc(),
					Char.u => readUniEsc(),
					Char.o => readOctEsc(),
					final c => (){ 
						final end = here;
						final preEnd = end.advance(-2);
						reader.next();
						throw StarError.invalidCharEscape(
							Span(begin, preEnd, source),
							c,
							Span(preEnd, end, source),
							Span.at(end, source)
						);
					}()
				};
			
			default:
				char = reader.eat();
		};
		
		if(reader.eatChar(Char.DQUOTE)) {
			return T_Char(span, char);
		} else {
			final end = here;
			throw StarError.unterminatedChar(
				Span(begin, end, source),
				Span.at(end, source)
			);
		}
	}

	Char readHexEsc() {
		final start = reader.offset;
		
		for(final _ in 2.times()) {
			if(reader.peekHex()) {
				reader.next();
			} else {
				final end = here;
				throw StarError.invalidHexEscape(
					Span(end.advance(reader.offset - start - 2), end, source),
					Span.at(end, source)
				);
			}
		}
		
		return int.parse(reader.substring(start), radix: 16).char;
	}

	Char readUniEsc() {
		final start = reader.offset;
		
		for(final _ in 4.times()) {
			if(reader.peekHex()) {
				reader.next();
			} else {
				final end = here;
				throw StarError.invalidUniEscape(
					Span(end.advance(reader.offset - start - 2), end, source),
					Span.at(end, source)
				);
			}
		}
		
		return int.parse(reader.substring(start), radix: 16).char;
	}

	Char readOctEsc() {
		final start = reader.offset;
		
		for(final _ in 3.times()) {
			if(reader.hasNext && switch(reader.unsafePeek()) {
				>= Char.ZERO && <= Char.SEVEN => true,
				_ => false
			}) {
				reader.next();
			} else {
				final end = here;
				throw StarError.invalidOctEscape(
					Span(end.advance(reader.offset - start - 2), end, source),
					Span.at(end, source)
				);
			}
		}
		
		return int.parse(reader.substring(start), radix: 8).char;
	}

	Token readStr() {
		var start = reader.offset;
		final segments = <StrSegment>[];

		loop: while(reader.hasNext) switch(reader.eat()) {
			case Char.DQUOTE:
				if(start != reader.offset - 1) {
					segments.add(StrSeg_Str(reader.substring(start, reader.offset - 1)));
				}
				break loop;
			
			case Char.BSLASH:
				final end = reader.offset;
				final esc = reader.eat();
				late final StrSegment seg;
				if(esc == Char.LPAREN) {
					trim();

					var level = 1;
					final tokens = <Token>[];

					while(level > 0) {
						final made = readToken();

						switch(made.k) {
							case K.lparen || K.hashLParen: level++;
							case K.rparen when --level == 0: break;
							default:
						}

						tokens.add(made);

						trim();
					}

					seg = StrSeg_Code(tokens);
				} else {
					seg = StrSeg_Char(switch(esc) {
						final c && (Char.BSLASH || Char.DQUOTE) => c,
						Char.t => Char.TAB,
						Char.n => Char.LF,
						Char.r => Char.CR,
						Char.v => Char(0x0b),
						Char.f => Char(0x0c),
						Char.ZERO => Char(0x00),
						Char.e => Char(0x1b),
						Char.a => Char(0x07),
						Char.b => Char(0x08),
						Char.x => readHexEsc(),
						Char.u => readUniEsc(),
						Char.o => readOctEsc(),
						final c => (){ 
							final end = here;
							final preEnd = end.advance(-2);
							reader.next();
							throw StarError.invalidCharEscape(
								Span(begin, preEnd, source),
								c,
								Span(preEnd, end, source),
								Span.at(end, source)
							);
						}()
					});
				}

				if(start != end - 1) {
					segments.add(StrSeg_Str(reader.substring(start, end - 1)));
				}
				start = reader.offset;
				
				segments.add(seg);
			
			default: continue;
		}

		if(!reader.hasNext) {
			throw StarError.unterminatedStr(Span.at(begin, source));
		}
		
		return T_Str(span, segments);
	}

	Token readAnonArg() {
		var depth = 0;

		while(reader.eatChar(Char.DOT)) depth++;

		if(reader.peekDigit()) {
			final start = reader.offset;
			do reader.next(); while(reader.peekDigit());
			
			if(reader.peekAlphaU()) {
				final end = here;
			
				while(reader.peekAlnumQ()) reader.next();
	
				final endName = here;
	
				throw StarError.nameAfterAnonArg(
					Span(begin, end, source),
					Span(end, endName, source)
				);
			} else {
				return T_AnonArg(span, depth: depth, nth: int.parse(reader.substring(start)));
			}
		} else {
			final end = here;
			throw StarError.unterminatedAnonArg(
				Span(begin, end, source),
				Span.at(end, source)
			);
		}
	}
}