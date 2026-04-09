import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';
import 'package:star/util.dart';

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
import 'kind.dart';
import 'tagged_case.dart';

class TaggedKind extends Kind {
	final taggedCases = <TaggedCase>[];
	DefaultInit? defaultInit = null;

	TaggedKind({required super.span, required super.name, required super.lookup});

	static TaggedKind fromAST(ITypeLookup lookup, ast.Kind k) {
		throw "todo";
	}


	/* implements IDecl */

	String get declName => "tagged kind";
}