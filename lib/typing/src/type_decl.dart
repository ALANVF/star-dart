import 'package:star/errors/errors.dart';
import 'package:star/util.dart';

import 'category.dart';
import 'ctx.dart';
import 'lookup_path.dart';
import 'traits.dart';
import 'type.dart';
import 'any_type_decl.dart';
import 'typevar.dart';
import 'cache.dart';
import 'type_path.dart';


abstract class TypeDecl extends AnyFullTypeDecl {
	final typevars = MultiMap<String, TypeVar>.empty();
	(Type?,)? hidden = null;
	final friends = <Type>[];
	final refinements = <TypeDecl>[];
	final refinees = <TypeDecl>[];

	TypeDecl({required super.span, required super.name, required super.lookup}) {
		thisType = Type.thisType(this);
	}


	/* implements IErrors */

	bool hasErrors() =>
		errors.isNotEmpty
		|| typevars.allValues.any((t) => t.hasErrors());
	
	List<StarError> allErrors() => [
		...errors,
		for(final t in typevars.allValues)
			...t.allErrors()
	];


	/* implements ITypeLookup */

	Type makeTypePath(TypePath path) => path.toType(this);

	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) {
		throw "todo";
	}

	Category? findCategory(Ctx ctx, Type cat, Type forType, AnyTypeDecl? from, [Cache cache = const Cache.empty()]) {
		throw "todo";
	}


	/* implements ITypeable */

	String fullName([TypeCache cache = const TypeCache.empty()]) {
		cache = cache.add(thisType);
		
		if(params.isEmpty) {
			return Type.getFullPath(this)!;
		} else {
			return (StringBuffer(Type.getFullPath(this)!)
			..write("[")
			..writeAll([for(final p in params) if(cache.contains(p)) "..." else p.fullName(cache)], ", ")
			..write("]")
			).toString();
		}
	}



}

/*
function makeTypePath(path: TypePath) {
	return path.toType(this);
}
*/