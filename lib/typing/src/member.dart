import 'package:star/text/src/span.dart';
import 'package:star/ast/src/ident.dart';
import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';

import 'traits.dart';
import 'type.dart';
import 'expr.dart';
import 'any_type_decl.dart';
import 'type_path.dart';


class Member implements IDecl {
	final errors = <StarError>[];
	AnyTypeDecl decl;
	Span span;
	Ident name;
	Type? type;
	var isStatic = false;
	(Type?,)? hidden = null;
	var isReadonly = false;
	(Ident?,)? getter = null;
	(Ident?,)? setter = null;
	var isNoinherit = false;
	ast.Expr? value = null;
	TExpr? typedValue = null;
	Member? refinee = null;

	Member({
		required this.decl,
		required this.span,
		required this.name,
		required this.type,
		required this.value,
	});

	static Member fromAST(AnyTypeDecl decl, ast.Member ast) {
		final declSpan = Span.range(ast.span, ast.name.span);

		final member = Member(
			decl: decl,
			span: ast.span,
			name: ast.name,
			type: ast.type == null? null : decl.makeTypePath(ast.type!.toPath),
			value: ast.value
		);

		Span? getterSpan, setterSpan;

		if(ast.attrs.isStatic != null) member.isStatic = true;

		switch(ast.attrs.isHidden) {
			case (_, var outsideOf?): member.hidden = (decl.makeTypePath(outsideOf.toPath),);
			case (_, null): member.hidden = (null,);
		}

		if(ast.attrs.isReadonly != null) member.isReadonly = true;

		if(ast.attrs.isGetter case (var s, var getter)) {
			getterSpan = s;
			member.getter = (getter,);
		}

		if(ast.attrs.isSetter case (var s, var setter)) {
			setterSpan = s;
			member.setter = (setter,);
		}

		if(ast.attrs.isNoinherit != null) member.isNoinherit = true;

		if(member.getter case (Ident(name: var n, span: var s),)) if(n == ast.name.name) {
			member.errors.add(StarError.redundantGetter(n, declSpan, Span.range(getterSpan!, s)));
		}

		if(member.setter case (Ident(name: var n, span: var s),)) if(n == ast.name.name) {
			member.errors.add(StarError.redundantSetter(n, declSpan, Span.range(setterSpan!, s)));
		}

		switch(member) {
			case Member(getter: (null,), setter: (null,)):
			case Member(getter: (var i1?,), setter: (var i2?,)) when i1.name == ast.name.name && i1.name == i2.name:
				member.errors.add(StarError.redundantGetterSetter(member.name.name, declSpan, getterSpan!, setterSpan!));
		}
		
		return member;
	}
	

	/* implements IErrors */

	bool hasErrors() => errors.isNotEmpty;

	List<StarError> allErrors() => errors;


	/* implements IDecl */

	String get declName => "member";
}