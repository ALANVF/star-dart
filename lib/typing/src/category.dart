import 'package:star/ast/ast.dart' as ast;
import 'package:star/ast/ast.dart' show Ident;
import 'package:star/text/src/span.dart';
import 'package:star/errors/errors.dart';
import 'package:star/typing/src/ctx.dart';
import 'package:star/util.dart';

import 'traits.dart';
import 'any_type_decl.dart';
import 'any_method.dart';
import 'operator.dart';
import 'member.dart';
import 'type_decl.dart';
import 'type.dart';
import 'typevar.dart';
import 'type_path.dart';
import 'lookup_path.dart';
import 'cache.dart';

class Category extends AnyTypeDecl {
	final typevars = MultiMap<String, TypeVar>.empty();
	late Type path;
	late Type? target;
	final staticMembers = <Member>[];
	final staticMethods = <StaticMethod>[];
	final methods = <Method>[];
	final inits = <Init>[];
	final operators = <Operator>[];
	StaticInit? staticInit = null;
	StaticDeinit? staticDeinit = null;
	(Type?,)? hidden = null;
	final friends = <Type>[];

	Category({required super.span, required super.name, required super.lookup});

	static Category fromAST(ITypeLookup lookup, ast.Category c) {
		final category = Category(
			lookup: lookup,
			span: c.span,
			name: Ident(c.path.simpleName, c.path.span),
		);

		category.path = c.path.toPath.toType(category);
		category.target = c.target != null ? category.makeTypePath(c.target!.toPath) : null;

		category.thisType = category.target ?? (lookup as AnyTypeDecl).thisType;

		for(final t in c.typevars) {
			final tv = TypeVar.fromAST(category, t);
			category.typevars.add(tv.name.name, tv);
		}

		switch(c.attrs.isHidden) {
			case (_, var outsideOf?): category.hidden = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): category.hidden = (null,);
		}

		switch(c.attrs.isFriend) {
			case (_, ast.OneType(:var type)): category.friends.add(category.makeTypePath(type.toPath));
			case (_, ast.ManyTypes(:var types)):
				for(final type in types) category.friends.add(category.makeTypePath(type.toPath));
		}

		for(final decl in c.body.of) switch(decl) {
			case ast.Member m when m.attrs.isStatic != null: category.staticMembers.add(Member.fromAST(category, m));
			
			case ast.Method m when m.attrs.isStatic != null:
				if(StaticMethod.fromAST(category, m) case var mth?) category.staticMethods.add(mth);
			case ast.Method m:
				category.methods.add(Method.fromAST(category, m));
			
			case ast.Init i: category.inits.add(Init.fromAST(category, i));

			case ast.Operator o:
				if(Operator.fromAST(category, o) case var op?) category.operators.add(op);
			
			case ast.DefaultInit i when i.attrs.isStatic != null:
				if(category.staticInit != null) category.errors.add(StarError.duplicateDecl(decl, category));
				else category.staticInit = StaticInit.fromAST(category, i);
			
			case ast.Deinit d when d.attrs.isStatic != null:
				if(category.staticDeinit != null) category.errors.add(StarError.duplicateDecl(decl, category));
				else category.staticDeinit = StaticDeinit.fromAST(category, d);
			
			default:
				category.errors.add(StarError.unexpectedDecl(decl, category));
		}


		return category;
	}


	/* implements IErrors */

	bool hasErrors() =>
		(  errors.isNotEmpty
		|| typevars.allValues.any((t) => t.hasErrors())
		|| staticMembers.any((m) => m.hasErrors())
		|| staticMethods.any((m) => m.hasErrors())
		|| methods.any((m) => m.hasErrors())
		|| inits.any((i) => i.hasErrors())
		|| operators.any((o) => o.hasErrors())
		|| (staticInit?.hasErrors() ?? false)
		|| (staticDeinit?.hasErrors() ?? false));

	List<StarError> allErrors() => [
		...errors,
		for(final t in typevars.allValues) ...t.allErrors(),
		for(final m in staticMembers) ...m.allErrors(),
		for(final m in staticMethods) ...m.allErrors(),
		for(final m in methods) ...m.allErrors(),
		for(final i in inits) ...i.allErrors(),
		for(final o in operators) ...o.allErrors(),
		... staticInit?.allErrors() ?? [],
		... staticDeinit?.allErrors() ?? [],
	];


	/* implements IDecl */

	String get declName => "category";


	/* implements ITypeable */

	String fullName([TypeCache cache = const TypeCache.empty()]) => switch(target) {
		var target? => target.fullName(cache),
		_ => switch(lookup) {
			TypeDecl decl => decl.fullName(cache),
			TypeVar tvar => tvar.fullName(cache),
			_ => throw "???"
		}
	} + "+" + path.fullName(cache);
	

	/* implements ITypeLookup */

	Type makeTypePath(TypePath path) => path.toType(this);

	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) => throw "todo";

	Category? findCategory(Ctx ctx, Type cat, Type forType, AnyTypeDecl? from, [Cache cache = const Cache.empty()]) => throw "todo";
}