import 'package:star/errors/errors.dart';
import 'member.dart';
import 'operator.dart';
import 'tagged_case.dart';
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
import 'value_case.dart';

class TypeVar extends AnyFullTypeDecl {
	late List<Type> parents;
	TypeRule? rule;
	final members = <Member>[];
	final methods = <Method>[];
	final operators = <Operator>[];
	final staticMembers = <Member>[];
	final staticMethods = <StaticMethod>[];
	final taggedCases = <TaggedCase>[];
	final valueCases = <ValueCase>[];
	final categories = <Category>[];
	//NativeKind? native = null;`
	var isFlags = false;
	var isStrong = false;
	var isUncounted = false;

	TypeVar({
		required super.span,
		required super.name,
		required super.params,
		required super.lookup,
	});

	/* implements IErrors */

	bool hasErrors() =>
		(  errors.isNotEmpty
		|| members.any((m) => m.hasErrors())
		|| methods.any((m) => m.hasErrors())
		|| operators.any((o) => o.hasErrors())
		|| staticMembers.any((m) => m.hasErrors())
		|| staticMethods.any((m) => m.hasErrors())
		|| taggedCases.any((t) => t.hasErrors())
		|| valueCases.any((v) => v.hasErrors())
		|| categories.any((c) => c.hasErrors()));

	List<StarError> allErrors() => [
		...errors,
		for(final m in members) ...m.allErrors(),
		for(final m in methods) ...m.allErrors(),
		for(final o in operators) ...o.allErrors(),
		for(final m in staticMembers) ...m.allErrors(),
		for(final m in staticMethods) ...m.allErrors(),
		for(final t in taggedCases) ...t.allErrors(),
		for(final v in valueCases) ...v.allErrors(),
		for(final c in categories) ...c.allErrors(),
	];


	/* implements IDecl */
	
	String get declName => "type variable";



	/* implements ITypeable */
	
	String fullName([TypeCache cache = const TypeCache.empty()]) {
		return "TODO";
	}


	/* implements ITypeLookup */

	Type makeTypePath(TypePath path) => throw "TODO";

	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) => throw "TODO";

	Category? findCategory(Ctx ctx, Type cat, Type forType, AnyTypeDecl? from, [Cache cache = const Cache.empty()]) => throw "TODO";
}