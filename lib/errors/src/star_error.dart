import 'package:star/util.dart';
import 'package:star/reporting/reporting.dart';
import 'package:star/text/text.dart';
//import 'package:star/lexing/lexing.dart';

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
}

class StarError {
	final StarErrorKind kind;
	final Diagnostic diag;

	StarError.unterminatedComment(Span begin):
		kind = StarErrorKind.unterminatedComment,
		diag = Diagnostic.error(
			message: "Syntax error",
			info: [
				Info.primary(span: begin, message: "Unterminated comment"),
			]
		);
	
	StarError.invalidOperator(String name, Span span):
		kind = StarErrorKind.invalidOperator,
		diag = Diagnostic.error(
			message: "Syntax error",
			info: [
				Info.primary(span: span, message: "Invalid operator `$name`"),
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
}