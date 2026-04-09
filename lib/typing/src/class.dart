import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';
import 'package:star/util.dart';
import 'package:star/ast/src/ident.dart';

import 'category.dart';
import 'ctx.dart';
import 'lookup_path.dart';
import 'traits.dart';
import 'type.dart';
import 'any_type_decl.dart';
import 'typevar.dart';
import 'cache.dart';
import 'type_path.dart';
import 'member.dart';
import 'any_method.dart';
import 'operator.dart';
import 'class_like.dart';
import 'native_kind.dart';

class Class extends ClassLike {
	final inits = <Init>[];
	DefaultInit? defaultInit = null;
	Deinit? deinit = null;
	NativeKind? native = null;
	var isStrong = false;
	var isUncounted = false;

	Class({required super.span, required super.name, required super.lookup});

	static Class fromAST(ITypeLookup lookup, ast.Class c) {
		throw "todo";
	}


	/* implements IDecl */

	String get declName => "class";
}