import 'package:star/text/text.dart';
import 'ident.dart';
import 'delims.dart';
import 'type.dart';
import 'expr.dart';
import 'decl.dart';

class ClassAttrs {
	(Span, Type?)? isHidden;
	(Span, TypeSpec)? isFriend;
	(Span, Type?)? isSealed;
	Delims<List<(Ident, Expr)>>? isNative;
	Span? isStrong;
	Span? isUncounted;
}

class Class extends Namespace implements HasParents {
	final List<Type>? parents;
	final ClassAttrs attrs;

	Class(super.span, this.attrs, {
		required super.name,
		required super.typevars,
		required super.params,
		required super.body,
		required this.parents
	});

	String get displayName => "class";
}