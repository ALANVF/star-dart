import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';

import 'any_type_decl.dart';
import 'cache.dart';
import 'lookup_path.dart';
import 'traits.dart';
import 'type.dart';
import 'alias.dart';
import 'any_method.dart';
import 'operator.dart';

class OpaqueAlias extends Alias {
	late Type type;
	final staticMethods = <StaticMethod>[];
	final methods = <Method>[];
	final operators = <Operator>[];
	
	OpaqueAlias({required super.span, required super.name, required super.lookup});

	static OpaqueAlias fromAST(ITypeLookup lookup, ast.Alias a) {
		throw "todo";
	}


	/* implements IDecl */

	String get declName => "opaque alias";


	/* implements IErrors */

	bool hasErrors() =>
		(  errors.isNotEmpty
		|| methods.any((m) => m.hasErrors())
		|| operators.any((o) => o.hasErrors())
		|| staticMethods.any((m) => m.hasErrors()));

	List<StarError> allErrors() => [
		...errors,
		for(final m in methods) ...m.allErrors(),
		for(final o in operators) ...o.allErrors(),
		for(final m in staticMethods) ...m.allErrors(),
	];
	
	
	/* implements ITypeDecl */
}