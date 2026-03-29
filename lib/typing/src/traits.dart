import 'package:star/text/text.dart';
import 'package:star/errors/errors.dart';

import 'any_type_decl.dart';
import 'type_path.dart';
import 'type.dart';
import 'cache.dart';
import 'lookup_path.dart';

enum Search {
	start,
	inside,
	outside
}

abstract interface class IErrors {
	List<StarError> get errors;

	bool hasErrors();
	List<StarError> allErrors();
}

abstract interface class IDecl implements IErrors {
	Span get span;

	String get declName;
}

abstract interface class ITypeLookup {
	Type makeTypePath(TypePath path);

	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]);
	/*
	function findCategory(
		ctx: Ctx,
		cat: Type,
		forType: Type,
		from: AnyTypeDecl,
		cache: Cache = Nil
	): Array<Category>;
	*/
}

abstract interface class ITypeLookupDecl implements ITypeLookup, IDecl {

}

abstract interface class ITypeable implements ITypeLookup {
	// Display info

	String fullName([TypeCache cache = const TypeCache.empty()]);
}

