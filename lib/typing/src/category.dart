
import 'package:star/text/src/span.dart';
import 'package:star/errors/errors.dart';

import 'traits.dart';
import 'any_type_decl.dart';
import 'type_decl.dart';
import 'type.dart';
import 'typevar.dart';
import 'type_path.dart';
import 'lookup_path.dart';
import 'cache.dart';

sealed class Category extends AnyTypeDecl {
	final typevars = <String, List<TypeVar>>{};
	Type path;
	Type? target;
	// ...
	(Type?,)? hidden = null;
	final friends = <Type>[];

	Category({
		required super.span, required super.name, required super.lookup,
		required this.path,
		required this.target
	});


	/* implements IErrors */

	@override bool hasErrors() => errors.isNotEmpty;
	
	@override List<StarError> allErrors() => errors;

	/*
	function hasErrors() {
		return errors.length != 0
			|| typevars.allValues().some(g -> g.hasErrors())
			|| staticMembers.some(m -> m.hasErrors())
			|| staticMethods.some(m -> m.hasErrors())
			|| methods.some(m -> m.hasErrors())
			|| inits.some(i -> i.hasErrors())
			|| operators.some(o -> o.hasErrors());
	}

	function allErrors() {
		var result = errors;
		
		for(typevar in typevars) result = result.concat(typevar.allErrors());
		for(member in staticMembers) result = result.concat(member.allErrors());
		for(method in staticMethods) result = result.concat(method.allErrors());
		for(method in methods) result = result.concat(method.allErrors());
		for(init in inits) result = result.concat(init.allErrors());
		for(op in operators) result = result.concat(op.allErrors());

		return result;
	}
	*/


	/* implements IDecl */

	@override
	String get declName => "category";

	//'ITypeLookup.findType', 'ITypeLookup.makeTypePath', and 'ITypeable.fullName'.


	/* implements ITypeable */

	@override
	String fullName([TypeCache cache = const TypeCache.empty()]) => switch(target) {
		var target? => target.fullName(cache),
		_ => switch(lookup) {
			TypeDecl decl => decl.fullName(cache),
			TypeVar tvar => tvar.fullName(cache),
			_ => throw "???"
		}
	} + "+" + path.fullName(cache);
	

	/* implements ITypeLookup */

	@override
	Type makeTypePath(TypePath path) => throw "todo";


}

/*
@:structInit
class Category extends AnyTypeDecl {
	@:optional final typevars = new MultiMap<String, TypeVar>();
	var path: Type;
	var type: Null<Type>;
	final staticMembers: Array<Member> = [];
	final staticMethods: Array<StaticMethod> = [];
	final methods: Array<Method> = [];
	final inits: Array<Init> = [];
	final operators: Array<Operator> = [];
	var staticInit: Option<StaticInit> = None;
	var staticDeinit: Option<StaticDeinit> = None;
	var hidden: Null<Option<Type>> = null;
	final friends: Array<Type> = [];
*/