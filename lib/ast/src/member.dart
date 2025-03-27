import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'ident.dart';
import 'type.dart';
import 'expr.dart';
import 'decl.dart';

class MemberAttrs {
	Span? isStatic;
	(Span, Type?)? isHidden;
	Span? isReadonly;
	(Span, Ident?)? isGetter;
	(Span, Ident?)? isSetter;
	Span? isNoinherit;
}

class Member extends NamedDecl {
	final Type? type;
	final MemberAttrs attrs;
	final Expr? value;

	Member(super.span, this.attrs, {
		required super.name,
		required this.type,
		required this.value
	});

	String get displayName => attrs.isStatic == null ? "instance member" : "static member";
}