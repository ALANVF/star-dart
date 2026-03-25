import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/text.dart';
import 'ident.dart';
import 'delims.dart';
import 'block.dart';
import 'expr.dart';
import 'message.dart';
import 'ops.dart';
import 'stmt.dart';

part 'cascade.freezed.dart';

enum Step { incr, decr }

typedef Nested = List<Cascade<Expr>>;

@Freezed(makeCollectionsUnmodifiable: false) // fix bc it has a dumb naming error with nested => _nested
sealed class CascadeKind<T> with _$CascadeKind<T> {
	CascadeKind._();

	factory CascadeKind.member(Ident member) = CMember<T>;
	factory CascadeKind.message(Message<T> message) = CMessage<T>;
	factory CascadeKind.assignMember(Ident member, Span assign, InfixOp<Assignable>? op, Expr expr) = CAssignMember<T>;
	factory CascadeKind.assignMessage(Message<T> message, Span assign, InfixOp<Assignable>? op, Expr expr) = CAssignMessage<T>;
	factory CascadeKind.stepMember(Ident member, Span assign, Step step) = CStepMember<T>;
	factory CascadeKind.stepMessage(Message<T> message, Span assign, Step step) = CStepMessage<T>;
	factory CascadeKind.block(Block block) = CBlock<T>;
}

final class Cascade<T> {
	final CascadeKind<T> kind;
	final Span span;
	final int depth;
	final List<Cascade<Expr>> nested;

	Cascade(this.kind, {required this.span, required this.depth, required this.nested});
}