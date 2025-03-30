import 'package:star/text/text.dart';
import 'ident.dart';
import 'delims.dart';
import 'type.dart';
import 'typevar.dart';

typedef Body = Delims<List<Decl>>;

abstract class Decl {
	Span span;

	Decl(this.span);

	String get displayName;
}

mixin IsGeneric {
	List<Typevar> get typevars;
}

abstract class NamedDecl extends Decl {
	final Ident name;

	NamedDecl(super.span, {required this.name});
}

mixin IsParametric on Decl {
	TypeArgs? get params;
}

abstract class TypeDecl extends NamedDecl with IsGeneric, IsParametric {
	final List<Typevar> typevars;
	final TypeArgs? params;

	TypeDecl(super.span, {
		required super.name,
		required this.typevars,
		required this.params
	});
}

abstract class Namespace extends TypeDecl {
	final Body body;

	Namespace(super.span, {
		required super.name,
		required super.typevars,
		required super.params,
		required this.body
	});
}

mixin HasParents {
	List<Type>? get parents;
}