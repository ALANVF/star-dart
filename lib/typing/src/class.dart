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
import 'type_path.dart';
import 'class_like.dart';
import 'native_kind.dart';
import 'kind.dart';
import 'protocol.dart';
import 'module.dart';
import 'alias.dart';

class Class extends ClassLike {
	final inits = <Init>[];
	DefaultInit? defaultInit = null;
	Deinit? deinit = null;
	NativeKind? native = null;
	var isStrong = false;
	var isUncounted = false;

	Class({required super.span, required super.name, required super.lookup});

	static Class fromAST(ITypeLookup lookup, ast.Class c) {
		final cls = Class(
			lookup: lookup,
			span: c.span,
			name: c.name
		);

		for(final t in c.typevars) {
			final tv = TypeVar.fromAST(cls, t);
			cls.typevars.add(tv.name.name, tv);
		}

		cls.params = [...c.params?.of.map((p) => cls.makeTypePath(p.toPath)) ?? []];
		cls.parents = [...c.parents?.map((p) => cls.makeTypePath(p.toPath)) ?? []];

		switch(c.attrs.isHidden) {
			case (_, var outsideOf?): cls.hidden = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): cls.hidden = (null,);
		}

		switch(c.attrs.isSealed) {
			case (_, var outsideOf?): cls.sealed = (lookup.makeTypePath(outsideOf.toPath),);
			case (_, null): cls.sealed = (null,);
		}

		switch(c.attrs.isFriend) {
			case (_, ast.OneType(:var type)): cls.friends.add(cls.makeTypePath(type.toPath));
			case (_, ast.ManyTypes(:var types)):
				for(final type in types) cls.friends.add(cls.makeTypePath(type.toPath));
		}

		if(c.attrs.isStrong != null) cls.isStrong = true;

		if(c.attrs.isUncounted != null) cls.isUncounted = true;

		if(c.attrs.isNative case var nat?) switch(nat.of) {
			case [(("repr", _), ast.ELitsym(name: var repr))]: switch(repr.name) {
				case "void": cls.native = NVoid();
				case "bool": cls.native = NBool();
				case "dec64": cls.native = NDec64();
				case "voidptr": cls.native = NVoidPtr();
				default: cls.errors.add(StarError.invalidAttribute(cls, cls.name.name, "native", nat.begin));
			}

			case [(("repr", _), ast.ELitsym(name: "ptr")), (("elem", _), ast.EType(type: var t))]:
				cls.native = NPtr(cls.makeTypePath(t.toPath));
			
			case [(("repr", _), ast.ELitsym(name: "float")), (("bits", _), ast.EInt(value: var bits))]: switch(bits) {
				case 32: cls.native = NFloat32();
				case 64: cls.native = NFloat64();
				default: cls.errors.add(StarError.invalidAttribute(cls, cls.name.name, "native", nat.begin));
			}

			case [(("repr", _), ast.ELitsym(name: "int")), (("bits", _), ast.EInt(value: var bits)), (("signed", _), ast.EBool(value: var signed))]: switch(bits) {
				case 8: cls.native = signed? NInt8() : NUInt8();
				case 16: cls.native = signed? NInt16() : NUInt16();
				case 32: cls.native = signed? NInt32() : NUInt32();
				case 64: cls.native = signed? NInt64() : NUInt64();
				default: cls.errors.add(StarError.invalidAttribute(cls, cls.name.name, "native", nat.begin));
			}

			default:
				cls.errors.add(StarError.invalidAttribute(cls, cls.name.name, "native", nat.begin));
		}

		for(final decl in c.body.of) switch(decl) {
			case ast.Member m when m.attrs.isStatic != null: cls.staticMembers.add(Member.fromAST(cls, m));
			case ast.Member m: cls.members.add(Member.fromAST(cls, m));
			
			case ast.Module m: cls.addTypeDecl(Module.fromAST(cls, m));
			case ast.Class c: cls.addTypeDecl(Class.fromAST(cls, c));
			case ast.Protocol p: cls.addTypeDecl(Protocol.fromAST(cls, p));
			case ast.Kind k: cls.addTypeDecl(Kind.fromAST(cls, k));
			case ast.Alias a: cls.addTypeDecl(Alias.fromAST(cls, a));
			case ast.Category c: cls.categories.add(Category.fromAST(cls, c));

			case ast.Method m when m.attrs.isStatic != null:
				if(StaticMethod.fromAST(cls, m) case var mth?) cls.staticMethods.add(mth);
			case ast.Method m:
				cls.methods.add(Method.fromAST(cls, m));
			
			case ast.Init i: cls.inits.add(Init.fromAST(cls, i));

			case ast.Operator o:
				if(Operator.fromAST(cls, o) case var op?) cls.operators.add(op);
			
			case ast.DefaultInit i when i.attrs.isStatic != null:
				if(cls.staticInit != null) cls.errors.add(StarError.duplicateDecl(decl, cls));
				else cls.staticInit = StaticInit.fromAST(cls, i);
			
			case ast.DefaultInit i:
				if(cls.defaultInit != null) cls.errors.add(StarError.duplicateDecl(decl, cls));
				else cls.defaultInit = DefaultInit.fromAST(cls, i);
			
			case ast.Deinit d when d.attrs.isStatic != null:
				if(cls.staticDeinit != null) cls.errors.add(StarError.duplicateDecl(decl, cls));
				else cls.staticDeinit = StaticDeinit.fromAST(cls, d);
			
			case ast.Deinit d:
				if(cls.deinit != null) cls.errors.add(StarError.duplicateDecl(decl, cls));
				else cls.deinit = Deinit.fromAST(cls, d);
			
			default:
				cls.errors.add(StarError.unexpectedDecl(decl, cls));
		}

		return cls;
	}


	/* implements IDecl */

	String get declName => "class";
}