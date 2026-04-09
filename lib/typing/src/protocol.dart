import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';
import 'package:star/util.dart';
import 'package:star/ast/src/ident.dart';

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
import 'class_like.dart';
import 'kind.dart';
import 'class.dart';
import 'module.dart';
import 'alias.dart';

class Protocol extends ClassLike {
	final inits = <Init>[];
	DefaultInit? defaultInit = null;
	Deinit? deinit = null;

	Protocol({required super.span, required super.name, required super.lookup});

	static Protocol fromAST(ITypeLookup lookup, ast.Protocol p) {
		final protocol = Protocol(
			lookup: lookup,
			span: p.span,
			name: p.name
		);

		for(final t in p.typevars) {
			final tv = TypeVar.fromAST(protocol, t);
			protocol.typevars.add(tv.name.name, tv);
		}

		protocol.params = [...p.params?.of.map((p) => protocol.makeTypePath(p.toPath)) ?? []];
		protocol.parents = [...p.parents?.map((p) => protocol.makeTypePath(p.toPath)) ?? []];

		switch(p.attrs.isHidden) {
			case (_, var outsideOf?): protocol.hidden = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): protocol.hidden = (null,);
		}

		switch(p.attrs.isSealed) {
			case (_, var outsideOf?): protocol.sealed = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): protocol.sealed = (null,);
		}

		switch(p.attrs.isFriend) {
			case (_, ast.OneType(:var type)): protocol.friends.add(protocol.makeTypePath(type.toPath));
			case (_, ast.ManyTypes(:var types)):
				for(final type in types) protocol.friends.add(protocol.makeTypePath(type.toPath));
		}

		for(final decl in p.body.of) switch(decl) {
			case ast.Member m when m.attrs.isStatic != null: protocol.staticMembers.add(Member.fromAST(protocol, m));
			case ast.Member m: protocol.members.add(Member.fromAST(protocol, m));
			
			case ast.Module m: protocol.addTypeDecl(Module.fromAST(protocol, m));
			case ast.Class c: protocol.addTypeDecl(Class.fromAST(protocol, c));
			case ast.Protocol p: protocol.addTypeDecl(Protocol.fromAST(protocol, p));
			case ast.Kind k: protocol.addTypeDecl(Kind.fromAST(protocol, k));
			case ast.Alias a: protocol.addTypeDecl(Alias.fromAST(protocol, a));
			case ast.Category c: protocol.categories.add(Category.fromAST(protocol, c));

			case ast.Method m when m.attrs.isStatic != null:
				if(StaticMethod.fromAST(protocol, m) case var mth?) protocol.staticMethods.add(mth);
			case ast.Method m:
				protocol.methods.add(Method.fromAST(protocol, m));
			
			case ast.Init i: protocol.inits.add(Init.fromAST(protocol, i));

			case ast.Operator o:
				if(Operator.fromAST(protocol, o) case var op?) protocol.operators.add(op);
			
			case ast.DefaultInit i when i.attrs.isStatic != null:
				if(protocol.staticInit != null) protocol.errors.add(StarError.duplicateDecl(decl, protocol));
				else protocol.staticInit = StaticInit.fromAST(protocol, i);
			
			case ast.DefaultInit i:
				if(protocol.defaultInit != null) protocol.errors.add(StarError.duplicateDecl(decl, protocol));
				else protocol.defaultInit = DefaultInit.fromAST(protocol, i);
			
			case ast.Deinit d when d.attrs.isStatic != null:
				if(protocol.staticDeinit != null) protocol.errors.add(StarError.duplicateDecl(decl, protocol));
				else protocol.staticDeinit = StaticDeinit.fromAST(protocol, d);
			
			case ast.Deinit d:
				if(protocol.deinit != null) protocol.errors.add(StarError.duplicateDecl(decl, protocol));
				else protocol.deinit = Deinit.fromAST(protocol, d);
			
			default:
				protocol.errors.add(StarError.unexpectedDecl(decl, protocol));
		}

		return protocol;
	}


	/* implements IDecl */

	String get declName => "protocol";
}