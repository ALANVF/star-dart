import 'package:star/errors/errors.dart';
import 'package:star/util.dart';

import 'member.dart';
import 'traits.dart';
import 'any_type_decl.dart';
import 'any_method.dart';
import 'cache.dart';
import 'type.dart';
import 'lookup_path.dart';
import 'type_path.dart';
import 'type_rule.dart';
import 'category.dart';
import 'ctx.dart';
import 'type_decl.dart';

abstract class Namespace extends TypeDecl {
	late List<Type> parents;
	final decls = MultiMap<String, TypeDecl>.empty();
	final sortedDecls = <TypeDecl>[];
	final staticMembers = <Member>[];
	final staticMethods = <StaticMethod>[];
	StaticInit? staticInit = null;
	StaticDeinit? staticDeinit = null;
	(Type?,)? sealed = null;
	final categories = <Category>[];

	Namespace({required super.span, required super.name, required super.lookup});

	void addTypeDecl(TypeDecl decl) {
		decls.add(decl.name.name, decl);
		sortedDecls.add(decl);
	}

	/* implements IErrors */

	@override
	bool hasErrors() =>
		(  super.hasErrors()
		|| sortedDecls.any((d) => d.hasErrors())
		|| staticMembers.any((m) => m.hasErrors())
		|| staticMethods.any((m) => m.hasErrors())
		|| categories.any((c) => c.hasErrors()));

	@override
	List<StarError> allErrors() => [
		...super.allErrors(),
		for(final d in sortedDecls) ...d.allErrors(),
		for(final m in staticMembers) ...m.allErrors(),
		for(final m in staticMethods) ...m.allErrors(),
		for(final c in categories) ...c.allErrors(),
	];
}