import 'package:star/text/text.dart';
import 'ident.dart';
import 'delims.dart';
import 'type.dart';
import 'expr.dart';
import 'decl.dart';

class ProtocolAttrs {
	(Span, Type?)? isHidden;
	(Span, TypeSpec)? isFriend;
	(Span, Type?)? isSealed;
}

class Protocol extends Namespace implements HasParents {
	final List<Type>? parents;
	final ProtocolAttrs attrs;

	Protocol(super.span, this.attrs, {
		required super.name,
		required super.typevars,
		required super.params,
		required super.body,
		required this.parents
	});

	String get displayName => "protocol";
}