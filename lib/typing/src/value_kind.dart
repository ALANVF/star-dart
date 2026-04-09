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
import 'value_case.dart';

class ValueKind extends Kind {
	Type? repr = null;
	final valueCases = <ValueCase>[];

	ValueKind({required super.span, required super.name, required super.lookup});

	static ValueKind fromAST(ITypeLookup lookup, ast.Kind k) {
		throw "todo";
	}


	/* implements IDecl */

	String get declName => "value kind";
}