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
import 'namespace.dart';
import 'kind.dart';
import 'class.dart';
import 'protocol.dart';
import 'alias.dart';

class Module extends Namespace {
	var isMain = false;
	Ident? native = null;

	Module({required super.span, required super.name, required super.lookup});

	static Module fromAST(ITypeLookup lookup, ast.Module m) {
		final module = Module(
			lookup: lookup,
			span: m.span,
			name: m.name
		);

		for(final a in m.typevars) {
			final tv = TypeVar.fromAST(module, a);
			module.typevars.add(tv.name.name, tv);
		}

		module.params = [...m.params?.of.map((p) => module.makeTypePath(p.toPath)) ?? []];
		module.parents = [...m.parents?.map((p) => module.makeTypePath(p.toPath)) ?? []];

		switch(m.attrs.isHidden) {
			case (_, var outsideOf?): module.hidden = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): module.hidden = (null,);
		}

		switch(m.attrs.isSealed) {
			case (_, var outsideOf?): module.sealed = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): module.sealed = (null,);
		}

		if(m.attrs.isMain != null) module.isMain = true;

		switch(m.attrs.isFriend) {
			case (_, ast.OneType(:var type)): module.friends.add(module.makeTypePath(type.toPath));
			case (_, ast.ManyTypes(:var types)):
				for(final type in types) module.friends.add(module.makeTypePath(type.toPath));
		}

		if(m.attrs.isNative case (_, var libName)) {
			module.native = libName;
		}

		for(final decl in m.body.of) switch(decl) {
			case ast.Member m:
				module.staticMembers.add(Member.fromAST(module, m)
											..isStatic = true);
			
			case ast.Module m: module.addTypeDecl(Module.fromAST(module, m));
			case ast.Class c: module.addTypeDecl(Class.fromAST(module, c));
			case ast.Protocol p: module.addTypeDecl(Protocol.fromAST(module, p));
			case ast.Kind k: module.addTypeDecl(Kind.fromAST(module, k));
			case ast.Alias a: module.addTypeDecl(Alias.fromAST(module, a));
			case ast.Category c: module.categories.add(Category.fromAST(module, c));

			case ast.Method m:
				if(StaticMethod.fromAST(module, m) case var mth?) module.staticMethods.add(mth);
			
			case ast.DefaultInit i:
				if(module.staticInit != null) module.errors.add(StarError.duplicateDecl(decl, module));
				else module.staticInit = StaticInit.fromAST(module, i);
			
			case ast.Deinit d:
				if(module.staticDeinit != null) module.errors.add(StarError.duplicateDecl(decl, module));
				else module.staticDeinit = StaticDeinit.fromAST(module, d);
			
			default:
				module.errors.add(StarError.unexpectedDecl(decl, module));
		}

		return module;
	}


	/* implements IDecl */

	String get declName => "module";
}