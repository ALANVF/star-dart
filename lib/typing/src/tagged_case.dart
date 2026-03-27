import 'package:star/text/src/span.dart';
import 'package:star/ast/src/ident.dart';
import 'package:star/ast/ast.dart' as ast;

import 'errors.dart';
import 'traits.dart';
import 'type.dart';
import 'expr.dart';
import 'stmt.dart';
import 'message.dart';
import 'any_type_decl.dart';
import 'multi_param.dart';


abstract class TaggedCase implements IDecl {
	final errors = <StarError>[];
	AnyTypeDecl decl;
	Span span;
	ast.Message<ast.Type>? assoc = null;
	List<ast.Stmt>? init = null;

	Message<Type>? typedAssoc = null;
	TStmts? typedInit = null;

	TaggedCase({
		required this.decl,
		required this.span,
	});


	/* implements IErrors */

	bool hasErrors() => errors.isNotEmpty;

	List<StarError> allErrors() => errors;


	/* implements IDecl */

	String get declName => "tagged case";
}

sealed class SingleTaggedCase extends TaggedCase {
	Ident name;

	SingleTaggedCase({
		required super.decl,
		required super.span,
		required this.name
	});
}

sealed class MultiTaggedCase extends TaggedCase {
	MultiParams name;

	MultiTaggedCase({
		required super.decl,
		required super.span,
		required this.name
	});
}