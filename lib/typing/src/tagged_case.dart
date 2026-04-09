import 'package:star/text/src/span.dart';
import 'package:star/ast/src/ident.dart';
import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';

import 'traits.dart';
import 'type.dart';
import 'stmt.dart';
import 'message.dart';
import 'any_type_decl.dart';
import 'multi_param.dart';


abstract class TaggedCase implements IDecl {
	final errors = <StarError>[];
	AnyTypeDecl decl;
	Span span;
	ast.Message<ast.Type>? assoc;
	List<ast.Stmt>? init;

	Message<Type>? typedAssoc = null;
	TStmts? typedInit = null;

	TaggedCase({
		required this.decl,
		required this.span,
		required this.assoc,
		required this.init
	});

	static TaggedCase fromAST(AnyTypeDecl decl, ast.Case tc) {
		switch(tc.kind) {
			case ast.CTagged(tag: ast.CTSingle(:var name), :var assoc):
				return SingleTaggedCase(
					decl: decl,
					span: tc.span,
					name: name,
					assoc: assoc,
					init: tc.init?.of
				);
			
			case ast.CTagged(tag: ast.CTMulti(:var params), :var assoc):
				return MultiTaggedCase(
					decl: decl,
					span: tc.span,
					params: [for(final p in params) MultiParam.fromUntyped(decl, p)],
					assoc: assoc,
					init: tc.init?.of
				);
			
			default:
				throw "error!";
		}
	}


	/* implements IErrors */

	bool hasErrors() => errors.isNotEmpty;

	List<StarError> allErrors() => errors;


	/* implements IDecl */

	String get declName => "tagged case";
}

class SingleTaggedCase extends TaggedCase {
	Ident name;

	SingleTaggedCase({
		required super.decl,
		required super.span,
		required super.assoc,
		required super.init,
		required this.name
	});
}

class MultiTaggedCase extends TaggedCase {
	MultiParams params;

	MultiTaggedCase({
		required super.decl,
		required super.span,
		required super.assoc,
		required super.init,
		required this.params
	});
}