import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/src/span.dart';
import 'category.dart';
import 'traits.dart';
import 'any_type_decl.dart';
import 'type_decl.dart';
import 'typevar.dart';
import 'lookup_path.dart';
import 'type_path.dart';
import 'ctx.dart';
import 'cache.dart';
import 'star_dir.dart';
import 'star_unit.dart';
import 'star_file.dart';

part 'type.freezed.dart';

@freezed
sealed class Type with _$Type implements ITypeable { Type._();
	factory Type.path(int depth, LookupPath lookup, ITypeLookup source, {Span? span}) = TPath;
	factory Type.lookup(Type type, LookupPath lookup, ITypeLookup source, {Span? span}) = TLookup;
	factory Type.concrete(TypeDecl decl, {Span? span}) = TConcrete;
	factory Type.instance(TypeDecl decl, List<Type> args, TypeVarCtx ctx, {Span? span}) = TInstance;
	factory Type.thisType(AnyTypeDecl decl, {Span? span}) = TThis;
	factory Type.blank({Span? span}) = TBlank;
	factory Type.multi(List<Type> types, {Span? span}) = TMulti;
	factory Type.applied(Type type, List<Type> args, {Span? span}) = TApplied;
	factory Type.typeVar(TypeVar typeVar, {Span? span}) = TTypeVar;
	factory Type.modular(Type type, StarUnit unit, {Span? span}) = TModular;

	static String? getFullPath(ITypeLookup lookup) {
		switch(lookup) {
			case StarFile file:
				if(file.dir case StarUnit unit) {
					StarDir dir = unit.outer;
					var name = unit.name;

					while(dir is StarUnit) {
						unit = dir;
						name = unit.name + '.' + name;
						dir = unit.outer;
					}

					return name;
				} else {
					return null;
				}

			case TypeDecl type:
				return switch(getFullPath(type.lookup)) {
					null => type.name.name,
					var p => '$p.${type.name.name}'
				};
			
			case TypeVar tvar:
				return switch(getFullPath(tvar.lookup)) {
					null => tvar.name.name,
					var p => '$p.#${tvar.name.name}'
				};
			
			// ignore: unreachable_switch_case
			case Category cat:
				return cat.thisType.fullName() + "+" + cat.path.fullName();
			
			default:
				return '??? $lookup';
		}
	}

	String get simpleName => "TODO";
	/*
		case TPath(depth, lookup, _):
			"_.".repeat(depth)
			+ lookup.mapArray((_, n, p) -> n + (p.length == 0 ? "" : '[${p.joinMap(", ", _ -> "...")}]')).join(".");
		
		case TLookup(type, lookup, _):
			type.simpleName()
			+ lookup.mapArray((_, n, p) -> '.$n' + (p.length == 0 ? "" : '[${p.joinMap(", ", _ -> "...")}]')).join("");
		
		case TConcrete({lookup: lookup, name: {name: name}, params: []}):
			getFullPath(lookup).map(p -> '$p.$name').orElse(name);
		case TConcrete({lookup: lookup, name: {name: name}, params: params}):
			getFullPath(lookup).map(p -> '$p.$name').orElse(name)
			+ '[${params.map(_ -> "...").join(", ")}]';
		
		case TInstance({lookup: lookup, name: {name: name}}, params, _):
			getFullPath(lookup).map(p -> '$p.$name').orElse(name)
			+ '[${params.map(_ -> '...').join(", ")}]';
		
		case TTypeVar({name: {name: name}, params: []}): name;
		case TTypeVar({name: {name: name}, params: params}): '$name[${params.map(_ -> "...").join(", ")}]';
		
		case TThis(_): "This";
		
		case TBlank: "_";
		
		case TMulti(types): types[0].simpleName();
		
		case TApplied(type, params): // Probably bad but eh
			final name = type.simpleName();
			(if(name.endsWith("]")) {
				name.removeAfter("[");
			} else {
				name;
			}) + "[" + params.map(p -> p.simpleName()).join(", ") + "]";
		
		case TModular(type, _): return type.simpleName();
	*/


	/* implements ITypeLookup */

	Type makeTypePath(TypePath path) => throw "bad";

	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) {
		throw "todo";
	}

	Category? findCategory(Ctx ctx, Type cat, Type forType, AnyTypeDecl? from, [Cache cache = const Cache.empty()]) {
		throw "todo";
	}


	/* implements ITypeable */

	String fullName([TypeCache cache = const TypeCache.empty()]) => "todo";
}
