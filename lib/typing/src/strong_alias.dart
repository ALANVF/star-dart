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
import 'member.dart';

class StrongAlias extends Alias {
	late Type type;
	final staticMembers = <Member>[];
	final staticMethods = <StaticMethod>[];
	final members = <Member>[];
	final methods = <Method>[];
	final operators = <Operator>[];
	StaticInit? staticInit = null;
	StaticDeinit? staticDeinit = null;
	var noInherit = false;

	StrongAlias({required super.span, required super.name, required super.lookup});

	static StrongAlias fromAST(ITypeLookup lookup, ast.Alias a) {
		throw "todo";
	}


	/* implements IDecl */

	String get declName => "strong alias";


	/* implements IErrors */

	bool hasErrors() =>
		(  errors.isNotEmpty
		|| members.any((m) => m.hasErrors())
		|| methods.any((m) => m.hasErrors())
		|| operators.any((o) => o.hasErrors())
		|| staticMembers.any((m) => m.hasErrors())
		|| staticMethods.any((m) => m.hasErrors())
		|| (staticInit?.hasErrors() ?? false)
		|| (staticDeinit?.hasErrors() ?? false));

	List<StarError> allErrors() => [
		...errors,
		for(final m in members) ...m.allErrors(),
		for(final m in methods) ...m.allErrors(),
		for(final o in operators) ...o.allErrors(),
		for(final m in staticMembers) ...m.allErrors(),
		for(final m in staticMethods) ...m.allErrors(),
		... staticInit?.allErrors() ?? [],
		... staticDeinit?.allErrors() ?? [],
	];
	
	
	/* implements ITypeDecl */
}