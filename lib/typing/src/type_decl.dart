import 'package:star/errors/errors.dart';

import 'traits.dart';
import 'type.dart';
import 'any_type_decl.dart';
import 'typevar.dart';
import 'cache.dart';
import 'type_path.dart';


abstract class TypeDecl extends AnyFullTypeDecl {
	final typevars = <String, List<TypeVar>>{};
	(Type?,)? hidden = null;
	final friends = <Type>[];
	final refinements = <TypeDecl>[];
	final refinees = <TypeDecl>[];

	TypeDecl({required super.span, required super.name, required super.params, required super.lookup}) {
		thisType = Type.thisType(this);
	}


	/* implements IErrors */

	@override
	bool hasErrors() =>
		errors.isNotEmpty
		|| typevars.values.any((ts) => ts.any((t) => t.hasErrors()));
	
	@override
	List<StarError> allErrors() => [
		...errors,
		for(final ts in typevars.values)
			for(final t in ts)
				...t.allErrors()
	];


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