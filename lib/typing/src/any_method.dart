import 'package:star/ast/ast.dart' as ast;
import 'package:star/ast/src/ident.dart';
import 'package:star/errors/errors.dart';
import 'package:star/text/src/span.dart';

import 'traits.dart';
import 'any_type_decl.dart';
import 'type.dart';
import 'stmt.dart';
import 'cache.dart';
import 'lookup_path.dart';
import 'type_path.dart';
import 'typevar.dart';
import 'multi_param.dart';


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
	var typevars = <String, List<TypeVar>>{};
	MultiParams params = [];
	late String fuzzyName;
	var isUnordered = false;

	MultiStaticMethod({required super.decl, required super.span, required super.ret});


	/* extends AnyMethod */

	String get methodName => fuzzyName.replaceAll(" ", "");
}

class MultiMethod extends StaticMethod {
	var typevars = <String, List<TypeVar>>{};
	MultiParams params = [];
	late String fuzzyName;
	var isUnordered = false;

	MultiMethod({required super.decl, required super.span, required super.ret});


	/* extends AnyMethod */

	String get methodName => fuzzyName.replaceAll(" ", "");
}

class MultiInit extends Init {
	var typevars = <String, List<TypeVar>>{};
	MultiParams params = [];
	late String fuzzyName;
	var isUnordered = false;

	MultiInit({required super.decl, required super.span});


	/* extends AnyMethod */

	String get methodName => fuzzyName.replaceAll(" ", "");
}


//===============================================================================//

class CastMethod extends Method {
	var typevars = <String, List<TypeVar>>{};
	late Type type;

	CastMethod({required super.decl, required super.span, super.ret});


	/* extends AnyMethod */

	String get methodName => type.simpleName;


	/* implements IErrors */

	@override
	bool hasErrors() => super.hasErrors() || typevars.values.any((ts) => ts.any((t) => t.hasErrors()));

	@override
	List<StarError> allErrors() => [
		...super.allErrors(),
		for(final ts in typevars.values)
			for(final t in ts)
				...t.allErrors()
	];
}