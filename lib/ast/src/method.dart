import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'delims.dart';
import 'ident.dart';
import 'type.dart';
import 'expr.dart';
import 'stmt.dart';
import 'decl.dart';
import 'typevar.dart';

part 'method.freezed.dart';

typedef MultiParam = ({
	Ident? label,
	Ident? name,
	Type type,
	Expr? value
});
typedef MultiParams = List<MultiParam>;

@freezed
sealed class MethodKind with _$MethodKind {
	factory MethodKind.single(Ident name) = MKSingle;
	factory MethodKind.multi(MultiParams params) = MKMulti;
	factory MethodKind.cast(Type type) = MKCast;
}

class MethodAttrs {
	Span? isStatic;
	(Span, Type?)? isHidden;
	Span? isMain;
	Span? isGetter;
	Span? isSetter;
	Span? isNoinherit;
	Span? isUnordered;
	(Span, Ident?)? isNative;
	Span? isInline;
	Span? isAsm;
	Span? isMacro;
}

class Method extends Decl implements IsGeneric {
	final List<Typevar> typevars;
	final Delims<MethodKind> spec;
	final Type? ret;
	final MethodAttrs attrs;
	final StmtBody? body;

	Method(super.span, this.attrs, {
		required this.typevars,
		required this.spec,
		required this.ret,
		required this.body
	});

	String get displayName => attrs.isStatic == null ? "instance method" : "static method";
}