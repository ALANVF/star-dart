import 'package:star/ast/ast.dart' as ast;

import 'traits.dart';
import 'type_decl.dart';
import 'direct_alias.dart';
import 'strong_alias.dart';
import 'opaque_alias.dart';

abstract class Alias extends TypeDecl {
	Alias({required super.span, required super.name, required super.lookup});

	static Alias fromAST(ITypeLookup lookup, ast.Alias a) => switch(a.kind) {
		ast.ADirect() => DirectAlias.fromAST(lookup, a),
		ast.AStrong() => StrongAlias.fromAST(lookup, a),
		ast.AOpaque() => OpaqueAlias.fromAST(lookup, a),
	};
}