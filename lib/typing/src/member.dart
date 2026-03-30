import 'package:star/text/src/span.dart';
import 'package:star/ast/src/ident.dart';
import 'package:star/ast/ast.dart' as ast;
import 'package:star/errors/errors.dart';

import 'traits.dart';
import 'type.dart';
import 'expr.dart';
import 'any_type_decl.dart';


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
		required this.type
	});

	/*
	static function fromAST(decl: AnyTypeDecl, ast: parsing.ast.decls.Member) {
		final declSpan = Span.range(ast.span, ast.name.span);

		final member: Member = {
			decl: decl,
			span: ast.span,
			name: ast.name,
			type: ast.type._and(t => decl.makeTypePath(t)),
			value: ast.value
		};

		var getterSpan = null;
		var setterSpan = null;

		for(attr => span in ast.attrs) switch attr {
			case IsStatic: member.isStatic = true;

			case IsHidden(_) if(member.hidden != null): member.errors.push(Type_DuplicateAttribute(member, ast.name.name, "hidden", span));
			case IsHidden(None): member.hidden = None;
			case IsHidden(Some(outsideOf)): member.hidden = Some(decl.makeTypePath(outsideOf));

			case IsReadonly: member.isReadonly = true;

			case IsGetter(_) if(member.getter != null): member.errors.push(Type_DuplicateAttribute(member, ast.name.name, "getter", span));
			case IsGetter(name):
				member.getter = name;
				getterSpan = span;

			case IsSetter(_) if(member.setter != null): member.errors.push(Type_DuplicateAttribute(member, ast.name.name, "setter", span));
			case IsSetter(name):
				member.setter = name;
				setterSpan = span;

			case IsNoinherit: member.noInherit = true;
		}

		switch member.getter {
			case Some({span: s, name: n}) if(n == ast.name.name):
				member.errors.push(Type_RedundantGetter(
					member.name.name,
					declSpan,
					n,
					Span.range(getterSpan.nonNull(), s)
				));
			
			default:
		}

		switch member.setter {
			case Some({span: s, name: n}) if(n == ast.name.name):
				member.errors.push(Type_RedundantSetter(
					member.name.name,
					declSpan,
					n,
					Span.range(setterSpan.nonNull(), s)
				));
			
			default:
		}

		switch member {
			case {getter: None, setter: None}:
				member.errors.push(Type_RedundantGetterSetter(
					member.name.name,
					declSpan,
					getterSpan.nonNull(),
					setterSpan.nonNull()
				));

			case {getter: Some({name: n1}), setter: Some({name: n2})} if(n1 == ast.name.name && n1 == n2):
				member.errors.push(Type_RedundantGetterSetter(
					member.name.name,
					declSpan,
					getterSpan.nonNull(),
					setterSpan.nonNull()
				));
				
			default:
		}

		return member;
	}
	*/


	/* implements IErrors */

	bool hasErrors() => errors.isNotEmpty;

	List<StarError> allErrors() => errors;


	/* implements IDecl */

	String get declName => "member";
}