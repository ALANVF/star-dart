import 'package:star/text/src/span.dart';
import 'package:star/ast/src/ident.dart';
import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';

import 'traits.dart';
import 'type.dart';
import 'expr.dart';
import 'any_type_decl.dart';


class Member implements IDecl {
	final errors = <StarError>[];
	AnyTypeDecl decl;
	Span span;
	Ident name;
	Type? type;
	var isStatic = false;
	(Type?,)? hidden = null;
	var isReadonly = false;
	(Ident?,)? getter = null;
	(Ident?,)? setter = null;
	var isNoinherit = false;
	ast.Expr? value = null;
	TExpr? typedValue = null;
	Member? refinee = null;

	Member({
		required this.decl,
		required this.span,
		required this.name,
		required this.type
	});


	/* implements IErrors */

	bool hasErrors() => errors.isNotEmpty;

	List<StarError> allErrors() => errors;


	/* implements IDecl */

	String get declName => "member";
}