import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/src/span.dart';
import 'traits.dart';
import 'any_type_decl.dart';
import 'type_decl.dart';
import 'typevar.dart';
import 'lookup_path.dart';
import 'ctx.dart';
import 'cache.dart';
import 'star_dir.dart';
import 'star_unit.dart';
import 'star_file.dart';

part 'type.freezed.dart';

@freezed
sealed class Type with _$Type { Type._();
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

	String get simpleName => "TODO";


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
			
			/*
			at(cat is Category) => {
				Some(cat.thisType.fullName()+"+"+cat.path.fullName());
			},
			*/
			
			default:
				return '??? $lookup';
		}
	}


	String fullName([TypeCache cache = const TypeCache.empty()]) => "todo";
}
