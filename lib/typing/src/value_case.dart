import 'package:star/ast/ast.dart' as ast;
import 'package:star/ast/src/ident.dart';
import 'package:star/text/src/span.dart';
import 'package:star/errors/errors.dart';

import 'traits.dart';
import 'expr.dart';
import 'any_type_decl.dart';


class ValueCase implements IDecl {
	final errors = <StarError>[];
	AnyTypeDecl decl;
	Span span;
	Ident name;
	ast.Expr? value;
	TExpr? typedValue = null;

	ValueCase({required this.decl, required this.span, required this.name});


	/* implements IErrors */

	bool hasErrors() => errors.isNotEmpty;

	List<StarError> allErrors() => errors;


	/* implements IDecl */

	String get declName => "value case";
}

/*
class ValueCase implements IErrors {
	final errors: Array<Error> = [];
	var decl: AnyTypeDecl;
	var span: Span;
	var name: Ident;
	var value: Null<Expr>;
	var typedValue: Null<TExpr> = null;

	static function fromAST(decl, ast: parsing.ast.decls.Case) {
		switch ast.kind {
			case Scalar(name, value):
				final valueCase: ValueCase = {
					decl: decl,
					span: ast.span,
					name: name,
					value: value
				};

				ast.init._and(init => {
					valueCase.errors.push(Type_NoValueCaseInit(
						name.name,
						Span.range(ast.span, name.span),
						Span.range(init.begin, init.end)
					));
				});

				return valueCase;
			
			default: throw "Error!";
		}
	}

	function declName() {
		return "value case";
	}

	function hasErrors() {
		return errors.length != 0;
	}

	function allErrors() {
		return errors;
	}
}
*/