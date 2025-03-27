import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/text.dart';
import 'ident.dart';
import 'block.dart';
import 'expr.dart';
import 'message.dart';
import 'ops.dart';
import 'stmt.dart';

part 'cascade.freezed.dart';

enum Step { incr, decr }

typedef Nested = List<Cascade<Expr>>;

@Freezed(makeCollectionsUnmodifiable: false) // fix bc it has a dumb naming error with nested => _nested
sealed class Cascade<T> with _$Cascade<T> {
	final Span span;
	final int depth;
	final List<Cascade<Expr>> nested;

	Cascade._({required this.span, required this.depth, required this.nested});

	factory Cascade.member(Ident member,
		{required Span span, required int depth, required Nested nested}) = CMember<T>;
	
	factory Cascade.message(Message<T> message,
		{required Span span, required int depth, required Nested nested}) = CMessage<T>;

	factory Cascade.assignMember(Ident member, Span assign, InfixOp<Assignable>? op, Expr expr,
		{required Span span, required int depth, required Nested nested}) = CAssignMember<T>;
	
	factory Cascade.assignMessage(Message<T> message, Span assign, InfixOp<Assignable>? op, Expr expr,
		{required Span span, required int depth, required Nested nested}) = CAssignMessage<T>;
	
	factory Cascade.stepMember(Ident member, Span assign, Step step,
		{required Span span, required int depth, required Nested nested}) = CStepMember<T>;
	
	factory Cascade.stepMessage(Message<T> message, Span assign, Step step,
		{required Span span, required int depth, required Nested nested}) = CStepMessage<T>;
	
	factory Cascade.block(Block block,
		{required Span span, required int depth, required Nested nested}) = CBlock<T>;
}