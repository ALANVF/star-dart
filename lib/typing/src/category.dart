
import 'package:star/text/src/span.dart';
import 'package:star/errors/errors.dart';
import 'package:star/typing/src/ctx.dart';
import 'package:star/util.dart';

import 'traits.dart';
import 'any_type_decl.dart';
import 'any_method.dart';
import 'operator.dart';
import 'member.dart';
import 'type_decl.dart';
import 'type.dart';
import 'typevar.dart';
import 'type_path.dart';
import 'lookup_path.dart';
import 'cache.dart';

class Category extends AnyTypeDecl {
	final typevars = MultiMap<String, TypeVar>.empty();
	Type path;
	Type? target;
	final staticMembers = <Member>[];
	final staticMethods = <StaticMethod>[];
	final methods = <Method>[];
	final inits = <Init>[];
	final operators = <Operator>[];
	StaticInit? staticInit = null;
	StaticDeinit? staticDeinit = null;
	(Type?,)? hidden = null;
	final friends = <Type>[];

	Category({
		required super.span, required super.name, required super.lookup,
		required this.path,
		required this.target
	});


	/* implements IErrors */

	bool hasErrors() =>
		(  errors.isNotEmpty
		|| typevars.allValues.any((t) => t.hasErrors())
		|| staticMembers.any((m) => m.hasErrors())
		|| staticMethods.any((m) => m.hasErrors())
		|| methods.any((m) => m.hasErrors())
		|| inits.any((i) => i.hasErrors())
		|| operators.any((o) => o.hasErrors()));

	List<StarError> allErrors() => [
		...errors,
		for(final t in typevars.allValues) ...t.allErrors(),
		for(final m in staticMembers) ...m.allErrors(),
		for(final m in staticMethods) ...m.allErrors(),
		for(final m in methods) ...m.allErrors(),
		for(final i in inits) ...i.allErrors(),
		for(final o in operators) ...o.allErrors()
	];


	/* implements IDecl */

	String get declName => "category";


	/* implements ITypeable */

	String fullName([TypeCache cache = const TypeCache.empty()]) => switch(target) {
		var target? => target.fullName(cache),
		_ => switch(lookup) {
			TypeDecl decl => decl.fullName(cache),
			TypeVar tvar => tvar.fullName(cache),
			_ => throw "???"
		}
	} + "+" + path.fullName(cache);
	

	/* implements ITypeLookup */

	Type makeTypePath(TypePath path) => path.toType(this);

	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) => throw "todo";

	Category? findCategory(Ctx ctx, Type cat, Type forType, AnyTypeDecl? from, [Cache cache = const Cache.empty()]) => throw "todo";
}