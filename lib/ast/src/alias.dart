import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/text.dart';
import 'ident.dart';
import 'type.dart';
import 'decl.dart';

part 'alias.freezed.dart';

class AliasAttrs {
	(Span, Type?)? isHidden;
	(Span, TypeSpec)? isFriend;
	Span? isNoInherit;
}

@freezed
sealed class AliasKind with _$AliasKind {
	factory AliasKind.opaque(Body? body) = AOpaque;
	factory AliasKind.direct(Type base) = ADirect;
	factory AliasKind.strong(Type base, Body? body) = AStrong;
}

class Alias extends TypeDecl {
	AliasAttrs attrs;
	AliasKind kind;

	Alias(super.span, this.attrs, this.kind, {
		required super.name,
		required super.typevars,
		required super.params
	});

	String get displayName => "alias";
}