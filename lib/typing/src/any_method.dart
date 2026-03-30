import 'package:star/ast/ast.dart' as ast;
import 'package:star/ast/src/ident.dart';
import 'package:star/errors/errors.dart';
import 'package:star/text/src/span.dart';
import 'package:star/util.dart';

import 'traits.dart';
import 'any_type_decl.dart';
import 'type.dart';
import 'stmt.dart';
import 'cache.dart';
import 'lookup_path.dart';
import 'type_path.dart';
import 'typevar.dart';
import 'multi_param.dart';
import 'category.dart';
import 'ctx.dart';


abstract class AnyMethod implements ITypeLookupDecl {
	final List<StarError> errors = [];
	AnyTypeDecl decl;
	Span span;
	(Type?,)? hidden = null;
	var noInherit = false;
	(Ident?,)? native = null;
	var isAsm = false;
	List<ast.Stmt>? body;
	List<TStmt>? typedBody = null;

	AnyMethod({required this.decl, required this.span});

	
	String get methodName;


	/* implements IErrors */

	bool hasErrors() => errors.isNotEmpty;

	List<StarError> allErrors() => errors;


	/* implements ITypeLookup */

	Type makeTypePath(TypePath path) => throw "todo";

	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) {
		return decl.findType(path, search, from, depth, cache);
	}

	Category? findCategory(Ctx ctx, Type cat, Type forType, AnyTypeDecl? from, [Cache cache = const Cache.empty()]) {
		return decl.findCategory(ctx, cat, forType, from, cache);
	}
}

abstract class StaticMethod extends AnyMethod {
	Type? ret;
	var isMain = false;
	var isGetter = false;
	var isSetter = false;
	var isInline = false;
	var isMacro = false;

	StaticMethod({required super.decl, required super.span, required this.ret});


	/* implements IDecl */

	String get declName => "static method";
}

abstract class Method extends AnyMethod {
	Type? ret;
	var isMain = false;
	var isGetter = false;
	var isSetter = false;
	var isInline = false;
	var isMacro = false;

	Method({required super.decl, required super.span, required this.ret});


	/* implements IDecl */

	String get declName => "static method";
}

abstract class Init extends AnyMethod {
	var isMacro = false;

	Init({required super.decl, required super.span});


	/* implements IDecl */

	String get declName => "initializer";
}


//===============================================================================//

class SingleStaticMethod extends StaticMethod {
	Ident name;

	SingleStaticMethod({
		required super.decl, required super.span, required super.ret,
		required this.name
	});


	/* extends AnyMethod */

	String get methodName => name.name;
}

class SingleMethod extends Method {
	Ident name;

	SingleMethod({
		required super.decl, required super.span, required super.ret,
		required this.name
	});


	/* extends AnyMethod */

	String get methodName => name.name;
}

class SingleInit extends Init {
	Ident name;

	SingleInit({
		required super.decl, required super.span,
		required this.name
	});


	/* extends AnyMethod */

	String get methodName => name.name;
}


//===============================================================================//


class MultiStaticMethod extends StaticMethod {
	var typevars = MultiMap<String, TypeVar>.empty();
	MultiParams params = [];
	late String fuzzyName;
	var isUnordered = false;

	MultiStaticMethod({required super.decl, required super.span, required super.ret});


	/* extends AnyMethod */

	String get methodName => fuzzyName.replaceAll(" ", "");
}

class MultiMethod extends StaticMethod {
	var typevars = MultiMap<String, TypeVar>.empty();
	MultiParams params = [];
	late String fuzzyName;
	var isUnordered = false;

	MultiMethod({required super.decl, required super.span, required super.ret});


	/* extends AnyMethod */

	String get methodName => fuzzyName.replaceAll(" ", "");
}

class MultiInit extends Init {
	var typevars = MultiMap<String, TypeVar>.empty();
	MultiParams params = [];
	late String fuzzyName;
	var isUnordered = false;

	MultiInit({required super.decl, required super.span});


	/* extends AnyMethod */

	String get methodName => fuzzyName.replaceAll(" ", "");
}


//===============================================================================//

class CastMethod extends Method {
	var typevars = MultiMap<String, TypeVar>.empty();
	late Type type;

	CastMethod({required super.decl, required super.span, super.ret});


	/* extends AnyMethod */

	String get methodName => type.simpleName;


	/* implements IErrors */

	@override
	bool hasErrors() => super.hasErrors() || typevars.allValues.any((t) => t.hasErrors());

	@override
	List<StarError> allErrors() => [
		...super.allErrors(),
		for(final t in typevars.allValues)
			...t.allErrors()
	];
}


//=====================================================================================//

abstract class EmptyMethod implements IDecl {
	final errors = <StarError>[];
	final AnyTypeDecl decl;
	final Span span;
	final List<ast.Stmt> body;
	List<TStmt>? typedBody = null;

	EmptyMethod({required this.decl, required this.span, required this.body});


	/* implements IErrors */

	bool hasErrors() => errors.isNotEmpty;

	List<StarError> allErrors() => errors;
}

class DefaultInit extends EmptyMethod {
	DefaultInit({required super.decl, required super.span, required super.body});

	static DefaultInit fromAST(AnyTypeDecl decl, ast.EmptyMethod ast) {
		return DefaultInit(decl: decl, span: ast.span, body: ast.body.stmts);
	}

	/* implements IDecl */

	String get declName => "default initializer";
}

class Deinit extends EmptyMethod {
	Deinit({required super.decl, required super.span, required super.body});

	static Deinit fromAST(AnyTypeDecl decl, ast.EmptyMethod ast) {
		return Deinit(decl: decl, span: ast.span, body: ast.body.stmts);
	}

	/* implements IDecl */

	String get declName => "deinitializer";
}

class StaticInit extends EmptyMethod {
	StaticInit({required super.decl, required super.span, required super.body});

	static StaticInit fromAST(AnyTypeDecl decl, ast.EmptyMethod ast) {
		return StaticInit(decl: decl, span: ast.span, body: ast.body.stmts);
	}

	/* implements IDecl */

	String get declName => "static initializer";
}

class StaticDeinit extends EmptyMethod {
	StaticDeinit({required super.decl, required super.span, required super.body});

	static StaticDeinit fromAST(AnyTypeDecl decl, ast.EmptyMethod ast) {
		return StaticDeinit(decl: decl, span: ast.span, body: ast.body.stmts);
	}

	/* implements IDecl */

	String get declName => "static deinitializer";
}