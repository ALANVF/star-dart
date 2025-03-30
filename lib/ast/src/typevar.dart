import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/text.dart';
import 'ident.dart';
import 'delims.dart';
import 'type.dart';
import 'expr.dart';
import 'decl.dart';

part 'typevar.freezed.dart';

class TypevarAttrs {
	Delims<List<(Ident, Expr)>>? isNative;
	Span? isFlags;
	Span? isStrong;
	Span? isUncounted;
}

class Typevar extends NamedDecl implements HasParents, IsParametric {
	final TypevarAttrs attrs;
	final TypeArgs? params;
	final List<Type>? parents;
	final (Span, TypevarRule)? rule;
	final Body? body;

	Typevar(super.span, this.attrs, {
		required super.name,
		required this.params,
		required this.parents,
		required this.rule,
		required this.body
	});

	String get displayName => "local typevar";
}

enum R_Test { eq, ne, of }
enum R_Cmp { lt, le, gt, ge }
enum R_Logic { and, or, xor, nor }

@freezed
sealed class TypevarRule with _$TypevarRule {
	factory TypevarRule.negate(Span span, Type type) = RNegate;
	factory TypevarRule.exists(Span span, Type type) = RExists;
	factory TypevarRule.test(Type left, R_Test op, List<(Span, Type)> chain) = RTest;
	factory TypevarRule.cmp(Type left, List<(Span, R_Cmp, Type)> chain) = RCmp;
	factory TypevarRule.logic(TypevarRule left, R_Logic op, TypevarRule right) = RLogic;
	factory TypevarRule.not(Span span, TypevarRule rule) = RNot;
	factory TypevarRule.paren(Span begin, TypevarRule rule, Span end) = RParen;
}