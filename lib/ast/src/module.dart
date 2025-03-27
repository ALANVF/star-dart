import 'package:star/text/text.dart';
import 'ident.dart';
import 'delims.dart';
import 'type.dart';
import 'expr.dart';
import 'decl.dart';

class ModuleAttrs {
	(Span, Type?)? isHidden;
	(Span, TypeSpec)? isFriend;
	(Span, Type?)? isSealed;
	Span? isMain;
	(Span, Ident)? isNative;
}

class Module extends Namespace implements HasParents {
	final List<Type>? parents;
	final ModuleAttrs attrs;

	Module(super.span, this.attrs, {
		required super.name,
		required super.typevars,
		required super.params,
		required super.body,
		required this.parents
	});

	String get displayName => "module";
}