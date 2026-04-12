import 'package:star/ast/ast.dart' as ast;
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
import 'member.dart';
import 'any_method.dart';
import 'operator.dart';
import 'tagged_case.dart';
import 'kind.dart';
import 'class.dart';
import 'protocol.dart';
import 'module.dart';
import 'alias.dart';

class TaggedKind extends Kind {
	final taggedCases = <TaggedCase>[];
	DefaultInit? defaultInit = null;

	TaggedKind({required super.span, required super.name, required super.lookup});

	static TaggedKind fromAST(ITypeLookup lookup, ast.Kind k) {
		final kind = TaggedKind(
			lookup: lookup,
			span: k.span,
			name: k.name
		);

		for(final t in k.typevars) {
			final tv = TypeVar.fromAST(kind, t);
			kind.typevars.add(tv.name.name, tv);
		}

		kind.params = [...k.params?.of.map((p) => kind.makeTypePath(p.toPath)) ?? []];
		kind.parents = [...k.parents?.map((p) => kind.makeTypePath(p.toPath)) ?? []];

		switch(k.attrs.isHidden) {
			case (_, var outsideOf?): kind.hidden = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): kind.hidden = (null,);
		}

		switch(k.attrs.isSealed) {
			case (_, var outsideOf?): kind.sealed = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): kind.sealed = (null,);
		}

		switch(k.attrs.isFriend) {
			case (_, ast.OneType(:var type)): kind.friends.add(kind.makeTypePath(type.toPath));
			case (_, ast.ManyTypes(:var types)):
				for(final type in types) kind.friends.add(kind.makeTypePath(type.toPath));
		}

		if(k.attrs.isStrong != null) kind.isStrong = true;

		if(k.attrs.isUncounted != null) kind.isUncounted = true;

		if(k.attrs.isFlags != null) kind.isFlags = true;

		for(final decl in k.body.of) switch(decl) {
			case ast.Member m when m.attrs.isStatic != null: kind.staticMembers.add(Member.fromAST(kind, m));
			case ast.Member m: kind.members.add(Member.fromAST(kind, m));
			
			case ast.Case c when c.kind is ast.CTagged: kind.taggedCases.add(TaggedCase.fromAST(kind, c));

			case ast.Module m: kind.addTypeDecl(Module.fromAST(kind, m));
			case ast.Class c: kind.addTypeDecl(Class.fromAST(kind, c));
			case ast.Protocol p: kind.addTypeDecl(Protocol.fromAST(kind, p));
			case ast.Kind k: kind.addTypeDecl(Kind.fromAST(kind, k));
			case ast.Alias a: kind.addTypeDecl(Alias.fromAST(kind, a));
			case ast.Category c: kind.categories.add(Category.fromAST(kind, c));

			case ast.Method m when m.attrs.isStatic != null:
				if(StaticMethod.fromAST(kind, m) case var mth?) kind.staticMethods.add(mth);
			case ast.Method m:
				kind.methods.add(Method.fromAST(kind, m));

			case ast.Operator o:
				if(Operator.fromAST(kind, o) case var op?) kind.operators.add(op);
			
			case ast.DefaultInit i when i.attrs.isStatic != null:
				if(kind.staticInit != null) kind.errors.add(StarError.duplicateDecl(decl, kind));
				else kind.staticInit = StaticInit.fromAST(kind, i);
			
			case ast.DefaultInit i:
				if(kind.defaultInit != null) kind.errors.add(StarError.duplicateDecl(decl, kind));
				else kind.defaultInit = DefaultInit.fromAST(kind, i);
			
			case ast.Deinit d when d.attrs.isStatic != null:
				if(kind.staticDeinit != null) kind.errors.add(StarError.duplicateDecl(decl, kind));
				else kind.staticDeinit = StaticDeinit.fromAST(kind, d);
			
			case ast.Deinit d:
				if(kind.deinit != null) kind.errors.add(StarError.duplicateDecl(decl, kind));
				else kind.deinit = Deinit.fromAST(kind, d);
			
			default:
				kind.errors.add(StarError.unexpectedDecl(decl, kind));
		}

		return kind;
	}


	/* implements IDecl */

	String get declName => "tagged kind";
}