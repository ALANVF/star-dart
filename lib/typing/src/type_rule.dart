import 'package:freezed_annotation/freezed_annotation.dart';

import 'expr.dart';
import 'traits.dart';
import 'type.dart';

part 'type_rule.freezed.dart';

@freezed
sealed class TypeRule with _$TypeRule { TypeRule._();
	factory TypeRule.eq(Type l, Type r) = REq;
	factory TypeRule.of(Type l, Type r) = ROf;
	factory TypeRule.lt(Type l, Type r) = RLt;
	factory TypeRule.le(Type l, Type r) = RLe;
	factory TypeRule.all(List<TypeRule> conds) = RAll;
	factory TypeRule.any(List<TypeRule> conds) = RAny;
	factory TypeRule.one(List<TypeRule> conds) = ROne;
	factory TypeRule.not(TypeRule rule) = RNot;
	factory TypeRule.negate(Type t) = RNegate;
	factory TypeRule.exists(Type t) = RExists;
}