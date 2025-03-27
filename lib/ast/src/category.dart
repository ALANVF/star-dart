import 'package:star/text/text.dart';
import 'ident.dart';
import 'delims.dart';
import 'type.dart';
import 'expr.dart';
import 'decl.dart';
import 'typevar.dart';

class CategoryAttrs {
	(Span, Type?)? isHidden;
	(Span, TypeSpec)? isFriend;
}

class Category extends Decl implements IsGeneric {
	final List<Typevar> typevars;
	final Type path;
	final Type? target;
	final CategoryAttrs attrs;
	final Body body;

	Category(super.span, this.attrs, {
		required this.typevars,
		required this.path,
		required this.target,
		required this.body
	});

	String get displayName => "class";
}