// ignore_for_file: unreachable_switch_case

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/text.dart';
import 'ident.dart';
import 'expr.dart';

part 'message.freezed.dart';

@freezed
sealed class Label with _$Label { Label._();
	factory Label.named(Ident name, Expr expr) = LNamed;
	factory Label.punned(Ident name) = LPunned;
	factory Label.anon(Expr expr) = LAnon;

	Span get span => switch(this) {
		LNamed(:var name) => name.span,
		LPunned(:var name) => name.span,
		LAnon(:var expr) => expr.mainSpan
	};
}

@freezed
sealed class Message<T> with _$Message<T> {
	final Type? category;
	Message._({required this.category});

	factory Message.single(Ident name, {required Type? category}) = MSingle<T>;
	factory Message.multi(List<Label> labels, {required Type? category}) = MMulti<T>;
	static Message<Expr> cast(Type type, {required Type? category}) => MCast(type, category: category);
}

class MCast extends Message<Expr> {
	final Type type;
	MCast(this.type, {required Type? category}): super._(category: category);
}