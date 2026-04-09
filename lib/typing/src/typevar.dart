import 'package:star/ast/src/ident.dart';
import 'package:star/errors/errors.dart';
import 'package:star/ast/ast.dart' as ast;

import 'member.dart';
import 'operator.dart';
import 'tagged_case.dart';
import 'traits.dart';
import 'any_type_decl.dart';
import 'any_method.dart';
import 'cache.dart';
import 'type.dart';
import 'lookup_path.dart';
import 'type_path.dart';
import 'type_rule.dart';
import 'category.dart';
import 'ctx.dart';
import 'value_case.dart';
import 'native_kind.dart';

class TypeVar extends AnyFullTypeDecl {
	late List<Type> parents;
	TypeRule? rule;
	final inits = <Init>[];
	final members = <Member>[];
	final methods = <Method>[];
	final operators = <Operator>[];
	final staticMembers = <Member>[];
	final staticMethods = <StaticMethod>[];
	final taggedCases = <TaggedCase>[];
	final valueCases = <ValueCase>[];
	final categories = <Category>[];
	NativeKind? native = null;
	var isFlags = false;
	var isStrong = false;
	var isUncounted = false;

	TypeVar({
		required super.span,
		required super.name,
		required super.lookup,
		required this.rule
	});

	static TypeVar fromAST(ITypeLookup lookup, ast.Typevar tv) {
		final typevar = TypeVar(
			lookup: lookup,
			span: tv.span,
			name: tv.name,
			rule: switch(tv.rule) {
				null => null,
				(_, var rule) => TypeRule.fromAST(lookup, rule)
			}
		);

		typevar.params = [...tv.params?.of.map((p) => typevar.makeTypePath(p.toPath)) ?? []];
		typevar.parents = [...tv.parents?.map((p) => typevar.makeTypePath(p.toPath)) ?? []];

		if(tv.attrs.isFlags != null) typevar.isFlags = true;
		
		if(tv.attrs.isStrong != null) typevar.isStrong = true;
		
		if(tv.attrs.isUncounted != null) typevar.isUncounted = true;

		if(tv.attrs.isNative case var nat?) switch(nat.of) {
			case [(("repr", _), ast.ELitsym(name: var repr))]: switch(repr.name) {
				case "void": typevar.native = NVoid();
				case "bool": typevar.native = NBool();
				case "dec64": typevar.native = NDec64();
				case "voidptr": typevar.native = NVoidPtr();
				default: typevar.errors.add(StarError.invalidAttribute(typevar, typevar.name.name, "native", nat.begin));
			}

			case [(("repr", _), ast.ELitsym(name: "ptr")), (("elem", _), ast.EType(type: var t))]:
				typevar.native = NPtr(typevar.makeTypePath(t.toPath));
			
			case [(("repr", _), ast.ELitsym(name: "float")), (("bits", _), ast.EInt(value: var bits))]: switch(bits) {
				case 32: typevar.native = NFloat32();
				case 64: typevar.native = NFloat64();
				default: typevar.errors.add(StarError.invalidAttribute(typevar, typevar.name.name, "native", nat.begin));
			}

			case [(("repr", _), ast.ELitsym(name: "int")), (("bits", _), ast.EInt(value: var bits)), (("signed", _), ast.EBool(value: var signed))]: switch(bits) {
				case 8: typevar.native = signed? NInt8() : NUInt8();
				case 16: typevar.native = signed? NInt16() : NUInt16();
				case 32: typevar.native = signed? NInt32() : NUInt32();
				case 64: typevar.native = signed? NInt64() : NUInt64();
				default: typevar.errors.add(StarError.invalidAttribute(typevar, typevar.name.name, "native", nat.begin));
			}

			default:
				typevar.errors.add(StarError.invalidAttribute(typevar, typevar.name.name, "native", nat.begin));
		}

		if(tv.body != null) for(final decl in tv.body!.of) switch(decl) {
			case ast.Member m when m.attrs.isStatic != null: typevar.staticMembers.add(Member.fromAST(typevar, m));
			case ast.Member m: typevar.members.add(Member.fromAST(typevar, m));

			case ast.Case c when c.kind is ast.CTagged: typevar.taggedCases.add(TaggedCase.fromAST(typevar, c));
			case ast.Case c when c.kind is ast.CScalar: typevar.valueCases.add(ValueCase.fromAST(typevar, c));

			case ast.Category c: typevar.categories.add(Category.fromAST(typevar, c));

			case ast.Method m when m.attrs.isStatic != null:
				if(StaticMethod.fromAST(typevar, m) case var sm?) typevar.staticMethods.add(sm);
			case ast.Method m:
				typevar.methods.add(Method.fromAST(lookup, m));
			
			case ast.Init i: typevar.inits.add(Init.fromAST(lookup, i));

			case ast.Operator o:
				if(Operator.fromAST(lookup, o) case var op?) typevar.operators.add(op);

			default:
				typevar.errors.add(StarError.unexpectedDecl(decl, typevar));
		}


		return typevar;
	}


	/* implements IErrors */

	bool hasErrors() =>
		(  errors.isNotEmpty
		|| members.any((m) => m.hasErrors())
		|| methods.any((m) => m.hasErrors())
		|| operators.any((o) => o.hasErrors())
		|| staticMembers.any((m) => m.hasErrors())
		|| staticMethods.any((m) => m.hasErrors())
		|| taggedCases.any((t) => t.hasErrors())
		|| valueCases.any((v) => v.hasErrors())
		|| categories.any((c) => c.hasErrors()));

	List<StarError> allErrors() => [
		...errors,
		for(final m in members) ...m.allErrors(),
		for(final m in methods) ...m.allErrors(),
		for(final o in operators) ...o.allErrors(),
		for(final m in staticMembers) ...m.allErrors(),
		for(final m in staticMethods) ...m.allErrors(),
		for(final t in taggedCases) ...t.allErrors(),
		for(final v in valueCases) ...v.allErrors(),
		for(final c in categories) ...c.allErrors(),
	];


	/* implements IDecl */
	
	String get declName => "type variable";



	/* implements ITypeable */
	
	String fullName([TypeCache cache = const TypeCache.empty()]) {
		return "TODO";
	}


	/* implements ITypeLookup */

	Type makeTypePath(TypePath path) => throw "TODO";

	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) => throw "TODO";

	Category? findCategory(Ctx ctx, Type cat, Type forType, AnyTypeDecl? from, [Cache cache = const Cache.empty()]) => throw "TODO";
}