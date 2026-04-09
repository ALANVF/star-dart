import 'package:star/typing/src/any_type_decl.dart';
import 'package:star/typing/src/traits.dart';
import 'package:star/util.dart';
import 'package:star/reporting/reporting.dart';
import 'package:star/text/text.dart';
import 'package:star/lexing/lexing.dart';
import 'package:star/ast/ast.dart' as ast;

enum StarErrorKind {
	unterminatedComment,
	invalidOperator,
	invalidInputAfterHash,
	invalidEqEq,
	unterminatedCascade,
	invalidInput,
	invalidHexStart,
	nameAfterHex,
	incompleteDecimalPoint,
	nameAfterNumber,
	missingExponent,
	noUppercasePunnedLabel,
	incompletePunnedLabel,
	noUppercaseLabel,
	escapeCharQuote,
	noEmptyChar,
	invalidCharEscape,
	unterminatedChar,
	invalidHexEscape,
	invalidUniEscape,
	invalidOctEscape,
	invalidStrEscape,
	unterminatedStr,
	nameAfterAnonArg,
	unterminatedAnonArg,

	unexpectedTokenWantedSep,
	unexpectedToken,
	unexpectedEOF,
	noGenericMember,
	noGenericCase,
	noGenericDeinit,
	nextWithRequiresExpr,

	tooManyErrors,
	unorganizedCode,
	unknownPragma,
	redundantGetter,
	redundantSetter,
	redundantGetterSetter,
	opNotOverloadable,
	opNeedsParameter,
	opDoesNotNeedParameter,
	unknownOpOverload,
	noTaggedKindRepr,
	noValueCaseInit,
	duplicateAttribute,
	invalidAttribute,
	duplicateDecl,
	duplicateDeclInFile,
	unexpectedDecl,
	unexpectedDeclInFile,
	invalidDecl,
	invalidDeclInFile,
	invalidTypeLookup,
	invalidTypeApply,
	notYetImplemented,
	duplicateParam,
	duplicateCaseParam,
	unknownFieldOrVar,
	shadowedLocalVar,
	localVarTypeMismatch,
	unknownMethod,
	unknownCast,
	unknownGetter,
	unknownSetter,
	unknownCategory,
	thisNotAllowed,
	expectedLogicalValue,
	possiblyUnintendedArrowBlock,
	arrayPatternNotAllowed,
	duplicateBinding,
	doesNotMatchReturnType,
}

class StarError {
	final StarErrorKind kind;
	final Diagnostic diag;

	StarError.unterminatedComment(Span begin):
		kind = StarErrorKind.unterminatedComment,
		diag = Diagnostic.error(
			message: "Syntax error",
			info: [
				Info.primary(span: begin, message: "Unterminated comment")
			]
		);
	
	StarError.invalidOperator(String name, Span span):
		kind = StarErrorKind.invalidOperator,
		diag = Diagnostic.error(
			message: "Syntax error",
			info: [
				Info.primary(span: span, message: "Invalid operator `$name`")
			]
		);

	StarError.invalidInputAfterHash(Char input, Span span, Span begin):
		kind = StarErrorKind.invalidInputAfterHash,
		diag = Diagnostic.error(
			message: "Syntax error",
			info: [
				Info.primary(
					span: span,
					message: "Unexpected `${input}` after `#`"
				),
				Info.secondary(span: begin)
			]
		);

	StarError.invalidEqEq(Span span):
		kind = StarErrorKind.invalidEqEq,
		diag = Diagnostic.error(
			message: "Syntax error",
			info: [
				Info.primary(
					span: span,
					message: "Please use `?=` instead of `==` in Star"
				)
			]
		);

	StarError.unterminatedCascade(Span begin, Span end):
		kind = StarErrorKind.unterminatedCascade,
		diag = Diagnostic.error(
			message: "Unterminated cascade",
			info: [
				Info.primary(
					span: end,
					message: "Expected a `>` to finish the cascade operator"
				),
				Info.secondary(span: begin)
			]
		);

	StarError.invalidInput(Span span):
		kind = StarErrorKind.invalidInput,
		diag = Diagnostic.error(
			message: "Syntax error",
			info: [
				Info.primary(
					span: span,
					message: "This is not the syntax that you are looking for"
				)
			]
		);

	StarError.invalidHexStart(Span begin):
		kind = StarErrorKind.invalidHexStart,
		diag = Diagnostic.error(
			message: "Unexpected start of hexdecimal literal",
			info: [
				Info.primary(
					span: begin,
					message: "Were you wanting a hexdecimal literal here or what?"
				)
			]
		);
	
	StarError.nameAfterHex(Span name, Span hex):
		kind = StarErrorKind.nameAfterHex,
		diag = Diagnostic.error(
			message: "Invalid hexdecimal literal",
			info: [
				Info.primary(
					span: name,
					message: "Make sure to separate names from numbers"
				),
				Info.secondary(span: hex)
			]
		);

	StarError.incompleteDecimalPoint(Span int, Span point):
		kind = StarErrorKind.incompleteDecimalPoint,
		diag = Diagnostic.error(
			message: "Invalid decimal literal",
			info: [
				Info.primary(
					span: point,
					message: "At least 1 digit is required on both sides of the decimal point"
				),
				Info.secondary(span: int)
			]
		);

	StarError.nameAfterNumber(Span name, Span num):
		kind = StarErrorKind.nameAfterNumber,
		diag = Diagnostic.error(
			message: "Invalid number literal",
			info: [
				Info.primary(
					span: name,
					message: "Make sure to separate names from numbers"
				),
				Info.secondary(span: num)
			]
		);

	StarError.missingExponent(Span e, Span exp):
		kind = StarErrorKind.missingExponent,
		diag = Diagnostic.error(
			message: "Invalid number literal",
			info: [
				Info.primary(
					span: exp,
					message: "Expected a number after the exponent indicator"
				),
				Info.secondary(
					span: e,
					message: "This indicates that the number has an exponent"
				)
			]
		);

	StarError.noUppercasePunnedLabel(Span begin, Span head, Span rest):
		kind = StarErrorKind.noUppercasePunnedLabel,
		diag = Diagnostic.error(
			message: "Invalid punned label",
			info: [
				Info.primary(
					span: head,
					message: "Punned labels may not start with an uppercase letter"
				),
				Info.secondary(span: begin),
				Info.secondary(span: rest)
			]
		);

	StarError.incompletePunnedLabel(Span begin, Span name):
		kind = StarErrorKind.incompletePunnedLabel,
		diag = Diagnostic.error(
			message: "Invalid punned label",
			info: [
				Info.primary(
					span: name,
					message: "Was expecting a name for the punned label"
				),
				Info.secondary(span: begin)
			]
		);

	StarError.noUppercaseLabel(Span head, Span rest):
		kind = StarErrorKind.noUppercaseLabel,
		diag = Diagnostic.error(
			message: "Invalid label",
			info: [
				Info.primary(
					span: head,
					message: "Labels may not start with an uppercase letter"
				),
				Info.secondary(span: rest)
			]
		);
	
	StarError.escapeCharQuote(Span begin, Span quote, Span end):
		kind = StarErrorKind.escapeCharQuote,
		diag = Diagnostic.error(
			message: "Invalid char literal",
			info: [
				Info.primary(
					span: quote,
					message: "`\"` characters need to be escaped in char literals"
				),
				Info.secondary(span: begin),
				Info.secondary(span: end)
			]
		);

	StarError.noEmptyChar(Span char):
		kind = StarErrorKind.noEmptyChar,
		diag = Diagnostic.error(
			message: "Invalid char literal",
			info: [
				Info.primary(
					span: char,
					message: "Char literals may not be empty"
				)
			]
		);

	StarError.invalidCharEscape(Span begin, Char char, Span span, Span end):
		kind = StarErrorKind.invalidCharEscape,
		diag = Diagnostic.error(
			message: "Invalid escape character",
			info: [
				// off by 1 errors?
				Info.primary(
					span: span,
					message: "Escape character `$char` " + (
						char == Char.LPAREN? "is not allowed in char literals" : "does not exist"
					)
				),
				Info.secondary(span: begin),
				Info.secondary(span: end)
			]
		);

	StarError.unterminatedChar(Span begin, Span end):
		kind = StarErrorKind.unterminatedChar,
		diag = Diagnostic.error(
			message: "Unterminated char literal",
			info: [
				Info.primary(
					span: end,
					message: "Expected another `\"` to finish the char literal"
				),
				Info.secondary(span: begin)
			]
		);

	StarError.invalidHexEscape(Span begin, Span esc):
		kind = StarErrorKind.invalidHexEscape,
		diag = Diagnostic.error(
			message: "Invalid hexdecimal escape code",
			info: [
				Info.primary(
					span: esc,
					message: "Was expecting a hexdecimal digit here"
				),
				Info.secondary(span: begin)
			]
		);

	StarError.invalidUniEscape(Span begin, Span esc):
		kind = StarErrorKind.invalidUniEscape,
		diag = Diagnostic.error(
			message: "Invalid unicode escape code",
			info: [
				Info.primary(
					span: esc,
					message: "Was expecting a hexdecimal digit here"
				),
				Info.secondary(span: begin)
			]
		);

	StarError.invalidOctEscape(Span begin, Span esc):
		kind = StarErrorKind.invalidOctEscape,
		diag = Diagnostic.error(
			message: "Invalid octal escape code",
			info: [
				Info.primary(
					span: esc,
					message: "Was expecting an octal digit here"
				),
				Info.secondary(span: begin)
			]
		);

	StarError.invalidStrEscape(Char char, Span span):
		kind = StarErrorKind.invalidStrEscape,
		diag = Diagnostic.error(
			message: "Invalid escape character",
			info: [
				Info.primary(
					span: span,
					message: "Escape character `\\$char` does not exist"
				)
			]
		);
	
	StarError.unterminatedStr(Span begin):
		kind = StarErrorKind.unterminatedStr,
		diag = Diagnostic.error(
			message: "Unterminated string",
			info: [
				Info.primary(
					span: begin,
					message: "This string is never terminated"
				)
			]
		);
	
	StarError.nameAfterAnonArg(Span name, Span arg):
		kind = StarErrorKind.nameAfterAnonArg,
		diag = Diagnostic.error(
			message: "Invalid anonymous argument",
			info: [
				Info.primary(
					span: name,
					message: "Make sure to separate names from numbers"
				),
				Info.secondary(span: arg)
			]
		);

	StarError.unterminatedAnonArg(Span begin, Span end):
		kind = StarErrorKind.unterminatedAnonArg,
		diag = Diagnostic.error(
			message: "Unterminated anonymous argument",
			info: [
				Info.primary(
					span: end,
					message: "Was expecting a number here"
				),
				Info.secondary(span: begin)
			]
		);
	

	// parser errors

	StarError.unexpectedTokenWantedSep(Token token):
		kind = StarErrorKind.unexpectedTokenWantedSep,
		diag = Diagnostic.error(
			message: "Syntax error",
			info: [
				Info.primary(
					span: token.span,
					message: "Unexpected ${token.k}, was expecting a comma or newline instead"
				)
			]
		);
	
	StarError.unexpectedToken(Token first, Token? last):
		kind = StarErrorKind.unexpectedToken,
		diag = Diagnostic.error(
			message: "Syntax error",
			info: (last != null && last != first) ? [
				Info.primary(
					span: last.span,
					message: "Unexpected ${last.k}"
				),
				Info.secondary(
					span: first.span,
					message: "Starting here"
				)
			] : [
				Info.primary(
					span: first.span,
					message: "Unexpected ${first.k}"
				)
			]
		);

	StarError.unexpectedEOF(Token first, Token last):
		kind = StarErrorKind.unexpectedEOF,
		diag = Diagnostic.error(
			message: "Syntax error",
			info: first == last ? [
				Info.primary(
					span: last.span,
					message: "Unexpected end of file after ${last.k}"
				)
			] : [
				Info.primary(
					span: last.span,
					message: "Unexpected end of file after ${last.k}"
				),
				Info.secondary(
					span: first.span,
					message: "Starting here"
				)
			]
		);

	StarError.noGenericMember(Span span):
		kind = StarErrorKind.noGenericMember,
		diag = Diagnostic.error(
			message: "Invalid member",
			info: [
				Info.primary(
					span: span,
					message: "Members are not allowed to be generic"
				)
			]
		);

	StarError.noGenericCase(Span span):
		kind = StarErrorKind.noGenericCase,
		diag = Diagnostic.error(
			message: "Invalid case",
			info: [
				Info.primary(
					span: span,
					message: "Cases are not allowed to be generic"
				)
			]
		);

	StarError.noGenericDeinit(Span span):
		kind = StarErrorKind.noGenericDeinit,
		diag = Diagnostic.error(
			message: "Invalid deinitializer",
			info: [
				Info.primary(
					span: span,
					message: "Deinitializers are not allowed to be generic"
				)
			]
		);

	StarError.nextWithRequiresExpr(Span span1, Span span2):
		kind = StarErrorKind.nextWithRequiresExpr,
		diag = Diagnostic.error(
			message: "Invalid statement",
			info: [
				Info.primary(
					span: span1,
					message: "`next` statement with `with:` label requires at least one value"
				),
				Info.secondary(
					span: span2,
					message: "Here"
				)
			]
		);
	

	// typer errors

	StarError.tooManyErrors():
		kind = StarErrorKind.tooManyErrors,
		diag = Diagnostic.error(
			message: "Too many errors!",
			info: []
		);

	StarError.unorganizedCode(Span span):
		kind = StarErrorKind.unorganizedCode,
		diag = Diagnostic.error(
			message: "Unorganized code",
			info: [
				Info.secondary(
					span: span,
					message: "All imports should be at the beginning of the file"
				)
			]
		);
	
	StarError.unknownPragma(String pragma, Span span):
		kind = StarErrorKind.unknownPragma,
		diag = Diagnostic.error(
			message: "Unknown pragma",
			info: [
				Info.primary(
					span: span,
					message: "Unknown pragma `$pragma`"
				)
			]
		);
	
	StarError.redundantGetter(String member, Span span, Span span2):
		kind = StarErrorKind.redundantGetter,
		diag = Diagnostic.warning(
			message: "Redundant code",
			info: [
				Info.primary(
					span: span,
					message: 'Unnecessary use of "is getter `$member`". Doing "is getter" is just fine'
				),
				Info.secondary(
					span: span2,
					message: "For member `$member`"
				)
			]
		);
	
	StarError.redundantSetter(String member, Span span, Span span2):
		kind = StarErrorKind.redundantSetter,
		diag = Diagnostic.warning(
			message: "Redundant code",
			info: [
				Info.primary(
					span: span,
					message: 'Unnecessary use of "is setter `$member`". Doing "is setter" is just fine'
				),
				Info.secondary(
					span: span2,
					message: "For member `$member`"
				)
			]
		);
	
	StarError.redundantGetterSetter(String member, Span span, Span getter, Span setter):
		kind = StarErrorKind.redundantGetterSetter,
		diag = Diagnostic.warning(
			message: "Redundant code",
			info: [
				Info.primary(
					span: getter,
					message: 'Unnecessary use of "is getter" along with "is setter"'
				),
				Info.primary(
					span: setter
				),
				Info.secondary(
					span: span,
					message: "For member `$member`"
				)
			]
		);
	
	StarError.opNotOverloadable(AnyTypeDecl decl, ast.Operator op, [bool yet = false]):
		kind = StarErrorKind.opNotOverloadable,
		diag = Diagnostic.error(
			message: "Invalid operator overload",
			info: [
				Info.primary(
					span: op.symbol.span,
					message: "The `${op.symbol.name}` operator cannot be overloaded" + (yet? " (yet)" : "")
				),
				Info.secondary(
					span: op.span
				),
				Info.secondary(
					span: decl.span,
					message: "For ${decl.declName} `${decl.fullName()}`"
				)
			]
		);
	
	StarError.opNeedsParameter(AnyTypeDecl decl, ast.Operator op):
		kind = StarErrorKind.opNeedsParameter,
		diag = Diagnostic.error(
			message: "Invalid operator overload",
			info: [
				Info.primary(
					span: op.symbol.span,
					message: "Overloading the `${op.symbol.name}` operator requires a parameter"
				),
				Info.secondary(
					span: op.span
				),
				Info.secondary(
					span: decl.span,
					message: "For ${decl.declName} `${decl.fullName()}`"
				)
			]
		);
	
	StarError.opDoesNotNeedParameter(AnyTypeDecl decl, ast.Operator op):
		kind = StarErrorKind.opDoesNotNeedParameter,
		diag = Diagnostic.error(
			message: "Invalid operator overload",
			info: [
				Info.primary(
					span: op.symbol.span,
					message: "Overloading the `${op.symbol.name}` operator should not require a parameter"
				),
				Info.secondary(
					span: op.span
				),
				Info.secondary(
					span: decl.span,
					message: "For ${decl.declName} `${decl.fullName()}`"
				)
			]
		);
	
	StarError.unknownOpOverload(AnyTypeDecl decl, ast.Operator op):
		kind = StarErrorKind.unknownOpOverload,
		diag = Diagnostic.error(
			message: "Invalid operator overload",
			info: [
				Info.primary(
					span: op.symbol.span,
					message: "The `${op.symbol.name}` operator cannot be overloaded because it does not exist"
				),
				Info.secondary(
					span: op.span
				),
				Info.secondary(
					span: decl.span,
					message: "For ${decl.declName} `${decl.fullName()}`"
				)
			]
		);
	
	/*StarError.noTaggedKindRepr(TaggedKind kind, Span repr):
		kind: StarErrorKind.noTaggedKindRepr,
		diag = Diagnostic.error(
			message: "Invalid declaration",
			info: [
				Info.primary(
					span: repr,
					message: "Tagged kinds may not have an underlaying type"
				),
				Info.secondary(
					span: kind.span,
					message: "For kind `${kind.name}`"
				)
			]
		)
	*/

	StarError.noValueCaseInit(String vcase, Span span, Span init):
		kind = StarErrorKind.noValueCaseInit,
		diag = Diagnostic.error(
			message: "Invalid value case",
			info: [
				Info.primary(
					span: init,
					message: "Value cases may not have an initializer"
				),
				Info.secondary(
					span: span,
					message: "For value case `$vcase`"
				)
			]
		);

	/* this should probably all be moved to the parser
	has [duplicateAttribute: decl (Decl), name (Str), attr (Str), span (Span)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Duplicate attribute"
			info: #[
				Info[
					:span
					message: "Duplicate attribute `is \(attr)`"
					priority: Priority.primary
				]
				Info[
					span: decl.span
					message: "For \(decl.declName) `\(name)`"
					priority: Priority.secondary
				]
			]
		]
	}*/

	StarError.invalidAttribute(IDecl decl, String name, String attr, Span span):
		kind = StarErrorKind.invalidAttribute,
		diag = Diagnostic.error(
			message: "Invalid attribute",
			info: [
				Info.primary(
					span: span,
					message: "Invalid attribute `is $attr`"
				),
				Info.secondary(
					span: decl.span,
					message: "For ${decl.declName} `$name`"
				)
			]
		);
	
	StarError.duplicateDecl(ast.Decl decl, AnyTypeDecl inDecl):
		kind = StarErrorKind.duplicateDecl,
		diag = Diagnostic.error(
			message: "Duplicate declaration",
			info: [
				Info.primary(
					span: decl.span,
					message: "Duplicate ${decl.displayName}"
				),
				Info.secondary(
					span: inDecl.span,
					message: "In ${inDecl.declName} `${inDecl.name.name}`"
				)
			]
		);

	/*
	has [duplicateDecl: decl' (UNamedDecl) inDecl: decl (AnyTypeDecl)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Duplicate declaration"
			info: #[
				Info[
					span: decl'.span
					message: "Duplicate \(decl'.name)"
					priority: Priority.primary
				]
				Info[
					span: decl.span
					message: "In \(decl.declName) `\(decl.name)`"
					priority: Priority.secondary
				]
			]
		]
	}
	has [duplicateDecl: decl' (UNamedDecl) inFile: file (File)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Duplicate declaration"
			info: #[
				Info[
					span: decl'.span
					message: "Duplicate \(decl'.name)"
					priority: Priority.primary
				]
			]
		]
	}*/

	StarError.unexpectedDecl(ast.Decl decl, AnyTypeDecl inDecl):
		kind = StarErrorKind.unexpectedDecl,
		diag = Diagnostic.error(
			message: "Unexpected declaration",
			info: [
				Info.primary(
					span: decl.span,
					message: "Unexpected ${decl.displayName}"
				),
				Info.secondary(
					span: inDecl.span,
					message: "In ${inDecl.declName} `${inDecl.name.name}`"
				)
			]
		);

	/*has [unexpectedDecl: decl' (UNamedDecl) inFile: file (File)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Unexpected declaration"
			info: #[
				Info[
					span: decl'.span
					message: "Unexpected \(decl'.name)"
					priority: Priority.primary
				]
			]
		]
	}

	has [invalidDecl: decl' (UNamedDecl) inDecl: decl (AnyTypeDecl)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Invalid declaration"
			info: #[
				Info[
					span: decl'.span
					message: "Invalid \(decl'.name)"
					priority: Priority.primary
				]
				Info[
					span: decl.span
					message: "In \(decl.declName) `\(decl.name)`"
					priority: Priority.secondary
				]
			]
		]
	}
	has [invalidDecl: decl' (UNamedDecl) inFile: file (File)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Invalid declaration"
			info: #[
				Info[
					span: decl'.span
					message: "Invalid \(decl'.name)"
					priority: Priority.primary
				]
			]
		]
	}

	has [invalidTypeLookup: span (Span) why: (Str) = "Invalid type lookup"] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Invalid type lookup"
			info: #[
				Info[
					:span
					message: why
					priority: Priority.primary
				]
			]
		]
	}

	has [invalidTypeApply: span (Span) why: (Str) = "Invalid type application"] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Invalid type application"
			info: #[
				Info[
					:span
					message: why
					priority: Priority.primary
				]
			]
		]
	}

	has [notYetImplemented: span (Span) why: (Str) = "This feature has not been implemented yet"] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Not yet implemented"
			info: #[
				Info[
					:span
					message: why
					priority: Priority.primary
				]
			]
		]
	}

	has [method: (RealMethod) duplicateParam: name (Str), origSpan (Span), dupSpan (Span)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Duplicate parameter"
			info: #[
				Info[
					span: dupSpan
					message: "Duplicate parameter `\(name)`"
					priority: Priority.primary
				]
				Info[
					span: origSpan
					message: "First defined here"
					priority: Priority.secondary
				]
				Info[
					span: method.span
					message: "For \(method.declName) `\(method.methodName)`"
					priority: Priority.secondary
				]
			]
		]
	}

	has [taggedCase: tcase (TaggedCase.Multi) duplicateParam: name (Str), origSpan (Span), dupSpan (Span)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Duplicate parameter"
			info: #[
				Info[
					span: dupSpan
					message: "Duplicate parameter `\(name)`"
					priority: Priority.primary
				]
				Info[
					span: origSpan
					message: "First defined here"
					priority: Priority.secondary
				]
				Info[
					span: tcase.span
					message: "For \(tcase.declName) `\(tcase.params[displayLabels])`"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) unknownFieldOrVar: name (Str), span (Span)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Unknown name"
			info: #[
				Info[
					:span
					message: "Unknown field or variable `\(name)`"
					priority: Priority.primary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) shadowedLocalVar: name (Str), origSpan (Span), dupSpan (Span)] {
		diag = Diagnostic[
			severity: Severity.warning
			message: "Shadowed variable"
			info: #[
				Info[
					span: dupSpan
					message: "This shadows an existing local variable `\(name)`"
					priority: Priority.primary
				]
				Info[
					span: origSpan
					message: "First defined here"
					priority: Priority.secondary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) localVarTypeMismatch: name (Str), gotType (Type), wantedType (Type), declSpan (Span), hereSpan (Span)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Type mismatch"
			info: #[
				Info[
					span: hereSpan
					message: "local variable `\(name)` declared to be of type `\(wantedType.fullName)`, but got `\(gotType.fullName)` instead"
					priority: Priority.primary
				]
				Info[
					span: declSpan
					message: "First defined here"
					priority: Priority.secondary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [
		ctx: (Ctx)
		sender: (Type)
		unknownMethod: kind (MethodKind), span (Span)
		categories: (Array[Category]) = #[]
		super: (Maybe[Type]) = Maybe[none]
	] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Unknown method"
			info: #[
				Info[
					:span
					message: {
						#{my access, my methodName} = kind[accessAndName]
						my msg = "\(access.desc) `\(sender.fullName)`"
						
						match super at Maybe[the: my super'] {
							msg[add: " does not have a supertype `\(super'.fullName)` that responds to method \(methodName)"]
						} else {
							msg[add: " does not respond to method \(methodName)"]
						}
						
						if categories? {
							msg[add: " in any categories of:"]
							for my cat in: categories {
								msg[add: "\n    \(cat.fullName)"]
							}
						}
						
						return msg
					}
					priority: Priority.primary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) sender: (Type) unknownCast: target (Type), span (Span) categories: (Array[Category]) = #[]] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Unknown cast"
			info: #[
				Info[
					:span
					message: {
						my msg = "Value of type `\(sender.fullName)` cannot be cast to type `\(target.fullName)`"
						
						if categories? {
							msg[add: " in any categories of:"]
							for my cat in: categories {
								msg[add: "\n    \(cat.fullName)"]
							}
						}
	
						return msg
					}
					priority: Priority.primary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) sender: (Type) access: (Access) unknownGetter: name (Str), span (Span)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Unknown name access"
			info: #[
				Info[
					:span
					message: "\(access.desc) `\(sender.fullName)` does not have member/getter `\(name)`"
					priority: Priority.primary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) sender: (Type) access: (Access) unknownSetter: name (Str), span (Span) value: (Maybe[Expr])] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Unknown name access"
			info: #[
				Info[
					:span
					message: {
						my msg = "\(access.desc) `\(sender.fullName)` does not have member/setter `\(name)`"
	
						match value at Maybe[the: my expr] {
							msg[add: " of type \({
								match expr.t at Maybe[the: my t] {
									return t.fullName
								} else {
									return "???"
								}
							})"]
						}
	
						return msg
					}
					priority: Priority.primary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) sender: (Type) access: (Access) unknownCategory: cat (Category), span (Span)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Unknown cast"
			info: #[
				Info[
					:span
					message: "\(access.desc) `\(sender.fullName)` does not have the category `\(cat.fullName)`"
					priority: Priority.primary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) thisNotAllowed: span (Span)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Invalid usage"
			info: #[
				Info[
					:span
					message: "`this` is not allowed in a static context"
					priority: Priority.primary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) expectedLogicalValue: span (Span) butGot: gotType (Type)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Invalid type"
			info: #[
				Info[
					:span
					message: "Expected a logical value, but got value of type `\(gotType.fullName)` instead"
					priority: Priority.primary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) possiblyUnintendedArrowBlock: span (Span)] {
		diag = Diagnostic[
			severity: Severity.warning
			message: "Possibly unintentional arrow shorthand"
			info: #[
				Info[
					:span
					message: "Using a block in an arrow shorthand does not act the same as a plain block!"
					priority: Priority.primary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) arrayPatternNotAllowed: span (Span)] {
		diag = Diagnostic[
			severity: Severity.error
			message: "Invalid pattern"
			info: #[
				Info[
					:span
					message: "This pattern is only allowed in array patterns"
					priority: Priority.primary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}

	has [ctx: (Ctx) duplicateBinding: name (Str), origSpan (Span), dupSpan (Span)] {
		diag = Diagnostic[
			severity: Severity.warning
			message: "Duplicate binding"
			info: #[
				Info[
					span: dupSpan
					message: "This shadows a previous binding `\(name)`"
					priority: Priority.primary
				]
				Info[
					span: origSpan
					message: "First defined here"
					priority: Priority.secondary
				]
				Info[
					span: ctx.typeLookup.span
					message: "In \(ctx.description)"
					priority: Priority.secondary
				]
			]
		]
	}
	*/
}