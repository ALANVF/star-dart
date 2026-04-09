import 'package:star/ast/ast.dart' as ast;

import 'lookup_path.dart';
import 'traits.dart';
import 'type.dart';
import 'type_path.dart';
import 'any_method.dart';
import 'class_like.dart';
import 'value_kind.dart';
import 'tagged_kind.dart';

abstract class Kind extends ClassLike {
	Deinit? deinit = null;
	var isFlags = false;
	var isStrong = false;
	var isUncounted = false;

	Kind({required super.span, required super.name, required super.lookup});

	static Kind fromAST(ITypeLookup lookup, ast.Kind k) {
		final cases = [
			for(final d in k.body.of)
				if(d is ast.Case)
					d
		];

		return cases.isNotEmpty && cases.every((c) => c.kind is ast.CScalar)
			? ValueKind.fromAST(lookup, k)
			: TaggedKind.fromAST(lookup, k);
	}
}