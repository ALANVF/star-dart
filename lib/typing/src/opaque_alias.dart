import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';

import 'any_type_decl.dart';
import 'cache.dart';
import 'lookup_path.dart';
import 'traits.dart';
import 'type.dart';
import 'alias.dart';
import 'any_method.dart';
import 'operator.dart';
import 'typevar.dart';
import 'type_path.dart';

class OpaqueAlias extends Alias {
	late Type type;
	final staticMethods = <StaticMethod>[];
	final methods = <Method>[];
	final operators = <Operator>[];
	
	OpaqueAlias({required super.span, required super.name, required super.lookup});

	static OpaqueAlias fromAST(ITypeLookup lookup, ast.Alias a) {
		final alias = OpaqueAlias(
			lookup: lookup,
			span: a.span,
			name: a.name
		);

		final ast.AOpaque(:body) = a.kind as ast.AOpaque;
		

		for(final t in a.typevars) {
			final tv = TypeVar.fromAST(alias, t);
			alias.typevars.add(tv.name.name, tv);
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

		if(body != null) for(final decl in body.of) switch(decl) {
			case ast.Method m when m.attrs.isStatic != null:
				if(StaticMethod.fromAST(alias, m) case var mth?) alias.staticMethods.add(mth);
			case ast.Method m:
				alias.methods.add(Method.fromAST(alias, m));
			
			case ast.Operator o:
				if(Operator.fromAST(alias, o) case var op?) alias.operators.add(op);
			
			default:
				alias.errors.add(StarError.unexpectedDecl(decl, alias));
		}

		return alias;
	}


	/* implements IDecl */

	String get declName => "opaque alias";


	/* implements IErrors */

	bool hasErrors() =>
		(  errors.isNotEmpty
		|| methods.any((m) => m.hasErrors())
		|| operators.any((o) => o.hasErrors())
		|| staticMethods.any((m) => m.hasErrors()));

	List<StarError> allErrors() => [
		...errors,
		for(final m in methods) ...m.allErrors(),
		for(final o in operators) ...o.allErrors(),
		for(final m in staticMethods) ...m.allErrors(),
	];
	
	
	/* implements ITypeDecl */
}