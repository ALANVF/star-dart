import 'package:star/errors/errors.dart';
import 'traits.dart';
import 'any_type_decl.dart';
import 'cache.dart';
import 'type.dart';
import 'lookup_path.dart';
import 'type_path.dart';
import 'type_rule.dart';

class TypeVar extends AnyFullTypeDecl {
	late List<Type> parents;
	TypeRule? rule;

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

	bool hasErrors() => (errors.isNotEmpty); // TODO

	List<StarError> allErrors() {
		return errors; // TODO
	}


	/* implements IDecl */
	
	String get declName => "type variable";



	/* implements ITypeable */
	
	String fullName([TypeCache cache = const TypeCache.empty()]) {
		return "TODO";
	}


	/* implements ITypeLookup */

	Type makeTypePath(TypePath path) => throw "TODO";

	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) => throw "TODO";
}