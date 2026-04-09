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

	ValueCase({required this.decl, required this.span, required this.name, required this.value});

	static ValueCase fromAST(AnyTypeDecl decl, ast.Case vc) {
		if(vc.kind case ast.CScalar(:var name, :var value)) {
			final valueCase = ValueCase(
				decl: decl,
				span: vc.span,
				name: name,
				value: value,
			);

			if(vc.init case var init?) {
				valueCase.errors.add(StarError.noValueCaseInit(
					name.name,
					Span.range(vc.span, name.span),
					Span.range(init.begin, init.end)
				));
			}

			return valueCase;
		} else {
			throw "error!";
		}
	}


	/* implements IErrors */

	bool hasErrors() => errors.isNotEmpty;

	List<StarError> allErrors() => errors;


	/* implements IDecl */

	String get declName => "value case";
}