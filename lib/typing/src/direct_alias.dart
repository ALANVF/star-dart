import 'package:star/ast/ast.dart' as ast;

import 'any_type_decl.dart';
import 'cache.dart';
import 'lookup_path.dart';
import 'traits.dart';
import 'type.dart';
import 'alias.dart';

class DirectAlias extends Alias {
	late Type type;
	
	DirectAlias({required super.span, required super.name, required super.lookup});

	static DirectAlias fromAST(ITypeLookup lookup, ast.Alias a) {
		throw "todo";
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