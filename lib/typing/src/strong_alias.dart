import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';

import 'any_type_decl.dart';
import 'cache.dart';
import 'lookup_path.dart';
import 'traits.dart';
import 'type.dart';
import 'alias.dart';
import 'any_method.dart';
import 'type_path.dart';
import 'operator.dart';
import 'member.dart';
import 'typevar.dart';

class StrongAlias extends Alias {
	late Type type;
	final staticMembers = <Member>[];
	final staticMethods = <StaticMethod>[];
	final members = <Member>[];
	final methods = <Method>[];
	final operators = <Operator>[];
	StaticInit? staticInit = null;
	StaticDeinit? staticDeinit = null;
	var noInherit = false;

	StrongAlias({required super.span, required super.name, required super.lookup});

	static StrongAlias fromAST(ITypeLookup lookup, ast.Alias a) {
		final alias = StrongAlias(
			lookup: lookup,
			span: a.span,
			name: a.name
		);

		final ast.AStrong(:base, :body) = a.kind as ast.AStrong;
		

		for(final t in a.typevars) {
			final tv = TypeVar.fromAST(alias, t);
			alias.typevars.add(tv.name.name, tv);
		}

		alias.params = [...a.params?.of.map((p) => alias.makeTypePath(p.toPath)) ?? []];
		
		alias.type = alias.makeTypePath(base.toPath);

		switch(a.attrs.isHidden) {
			case (_, var outsideOf?): alias.hidden = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): alias.hidden = (null,);
		}

		switch(a.attrs.isFriend) {
			case (_, ast.OneType(:var type)): alias.friends.add(alias.makeTypePath(type.toPath));
			case (_, ast.ManyTypes(:var types)):
				for(final type in types) alias.friends.add(alias.makeTypePath(type.toPath));
		}

		if(a.attrs.isNoinherit != null) alias.noInherit = true;

		if(body != null) for(final decl in body.of) switch(decl) {
			case ast.Member m when m.attrs.isStatic != null: alias.staticMembers.add(Member.fromAST(alias, m));
			case ast.Member m: alias.members.add(Member.fromAST(alias, m));

			case ast.Method m when m.attrs.isStatic != null:
				if(StaticMethod.fromAST(alias, m) case var mth?) alias.staticMethods.add(mth);
			case ast.Method m:
				alias.methods.add(Method.fromAST(alias, m));
			
			case ast.Operator o:
				if(Operator.fromAST(alias, o) case var op?) alias.operators.add(op);
			
			case ast.DefaultInit i when i.attrs.isStatic != null:
				if(alias.staticInit != null) alias.errors.add(StarError.duplicateDecl(decl, alias));
				else alias.staticInit = StaticInit.fromAST(alias, i);
			
			case ast.Deinit d when d.attrs.isStatic != null:
				if(alias.staticDeinit != null) alias.errors.add(StarError.duplicateDecl(decl, alias));
				else alias.staticDeinit = StaticDeinit.fromAST(alias, d);
			
			default:
				alias.errors.add(StarError.unexpectedDecl(decl, alias));
		}

		return alias;
	}


	/* implements IDecl */

	String get declName => "strong alias";


	/* implements IErrors */

	bool hasErrors() =>
		(  errors.isNotEmpty
		|| members.any((m) => m.hasErrors())
		|| methods.any((m) => m.hasErrors())
		|| operators.any((o) => o.hasErrors())
		|| staticMembers.any((m) => m.hasErrors())
		|| staticMethods.any((m) => m.hasErrors())
		|| (staticInit?.hasErrors() ?? false)
		|| (staticDeinit?.hasErrors() ?? false));

	List<StarError> allErrors() => [
		...errors,
		for(final m in members) ...m.allErrors(),
		for(final m in methods) ...m.allErrors(),
		for(final o in operators) ...o.allErrors(),
		for(final m in staticMembers) ...m.allErrors(),
		for(final m in staticMethods) ...m.allErrors(),
		... staticInit?.allErrors() ?? [],
		... staticDeinit?.allErrors() ?? [],
	];
	
	
	/* implements ITypeDecl */
}