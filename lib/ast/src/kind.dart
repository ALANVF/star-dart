import 'package:star/text/text.dart';
import 'ident.dart';
import 'delims.dart';
import 'type.dart';
import 'expr.dart';
import 'decl.dart';

class KindAttrs {
	(Span, Type?)? isHidden;
	(Span, TypeSpec)? isFriend;
	(Span, Type?)? isSealed;
	Span? isFlags;
	Span? isStrong;
	Span? isUncounted;
}

class Kind extends Namespace implements HasParents {
	final List<Type>? parents;
	final Type? repr;
	final KindAttrs attrs;

	Kind(super.span, this.attrs, {
		required super.name,
		required super.typevars,
		required super.params,
		required super.body,
		required this.parents,
		required this.repr
	});

	String get displayName => "kind";
}