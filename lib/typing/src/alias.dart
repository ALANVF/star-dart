import 'type_decl.dart';

abstract class Alias extends TypeDecl {
	Alias({required super.span, required super.name, required super.params, required super.lookup});


	/* implements IDecl */

	String get declName => "alias";
}

/*
package typing;

@:structInit
abstract class Alias extends TypeDecl {
	static function fromAST(lookup, ast: parsing.ast.decls.Alias): Alias {
		return switch ast.kind {
			case Direct(_, _): DirectAlias.fromAST(lookup, ast);
			case Strong(_, _): StrongAlias.fromAST(lookup, ast);
			case Opaque(_): OpaqueAlias.fromAST(lookup, ast);
		}
	}

	function declName() {
		return "alias";
	}
}
*/