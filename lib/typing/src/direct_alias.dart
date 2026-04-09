import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';

import 'any_type_decl.dart';
import 'cache.dart';
import 'lookup_path.dart';
import 'traits.dart';
import 'type.dart';
import 'alias.dart';
import 'typevar.dart';
import 'type_path.dart';

class DirectAlias extends Alias {
	late Type type;
	
	DirectAlias({required super.span, required super.name, required super.lookup});

	static DirectAlias fromAST(ITypeLookup lookup, ast.Alias a) {
		final alias = DirectAlias(
			lookup: lookup,
			span: a.span,
			name: a.name
		);

		for(final t in a.typevars) {
			final tv = TypeVar.fromAST(alias, t);
			alias.typevars.add(tv.name.name, tv);
		}

		if(a.kind case ast.ADirect(:var base)) {
			alias.type = alias.makeTypePath(base.toPath);
		}

		alias.params = [...a.params?.of.map((p) => alias.makeTypePath(p.toPath)) ?? []];

		switch(a.attrs.isHidden) {
			case (_, var outsideOf?): alias.hidden = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): alias.hidden = (null,);
		}

		switch(a.attrs.isFriend) {
			case (_, ast.OneType(:var type)): alias.friends.add(alias.makeTypePath(type.toPath));
			case (_, ast.ManyTypes(:var types)):
				for(final type in types) alias.friends.add(alias.makeTypePath(type.toPath));
		}

		if(a.attrs.isNoinherit case var na?) {
			alias.errors.add(StarError.invalidAttribute(alias, a.name.name, "noinherit", na));
		}

		return alias;
	}
	

	/* implements IDecl */
	String get declName => "type alias";

	
	/* implements ITypeDecl */
	
	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) {
		if(search == Search.inside) {
			return type.findType(path, search, from, depth, cache.add(thisType));
		} else {
			return super.findType(path, search, from, depth, cache);
		}
	}
}