import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/ast/ast.dart' as ast;
import 'package:star/ast/src/typevar.dart' show R_Cmp, R_Test, R_Logic;
import 'package:star/text/src/span.dart';

import 'expr.dart';
import 'traits.dart';
import 'type.dart';
import 'type_path.dart';

part 'type_rule.freezed.dart';


List<TypeRule> _recEq(ITypeLookup lookup, Type l1, List<(Span, ast.Type)> chain) {
	final res = <TypeRule>[];

	for(final (_, r) in chain) {
		final l2 = lookup.makeTypePath(r.toPath);
		res.add(REq(l1, l2));
		l1 = l2;
	}

	return res;
}

List<TypeRule> _recOf(ITypeLookup lookup, Type l1, List<(Span, ast.Type)> chain) {
	final res = <TypeRule>[];

	for(final (_, r) in chain) {
		final l2 = lookup.makeTypePath(r.toPath);
		res.add(ROf(l1, l2));
		l1 = l2;
	}

	return res;
}

List<TypeRule> _recCmp(ITypeLookup lookup, Type l1, List<(Span, R_Cmp, ast.Type)> chain) {
	final res = <TypeRule>[];

	for(final (_, op, r) in chain) {
		final l2 = lookup.makeTypePath(r.toPath);
		res.add(switch(op) {
			R_Cmp.gt => RLt(l2, l1),
			R_Cmp.ge => RLe(l2, l1),
			R_Cmp.lt => RLt(l1, l2),
			R_Cmp.le => RLe(l1, l2)
		});
		l1 = l2;
	}

	return res;
}

TypeRule _fromAST(ITypeLookup lookup, ast.TypevarRule parserRule) => switch(parserRule) {
	ast.RNegate(:var type) => RNegate(lookup.makeTypePath(type.toPath)),
	ast.RExists(:var type) => RExists(lookup.makeTypePath(type.toPath)),

	ast.RTest(:var left, op: R_Test.eq, chain: [(_, var r)]) => REq(lookup.makeTypePath(left.toPath), lookup.makeTypePath(r.toPath)),
	ast.RTest(:var left, op: R_Test.eq, :var chain) => RAll(_recEq(lookup, lookup.makeTypePath(left.toPath), chain)),

	ast.RTest(:var left, op: R_Test.ne, chain: [(_, var r)]) => RNot(REq(lookup.makeTypePath(left.toPath), lookup.makeTypePath(r.toPath))),
	ast.RTest(:var left, op: R_Test.ne, :var chain) => RNot(RAll(_recEq(lookup, lookup.makeTypePath(left.toPath), chain))),

	ast.RTest(:var left, op: R_Test.of, chain: [(_, var r)]) => ROf(lookup.makeTypePath(left.toPath), lookup.makeTypePath(r.toPath)),
	ast.RTest(:var left, op: R_Test.of, :var chain) => RAll(_recOf(lookup, lookup.makeTypePath(left.toPath), chain)),

	ast.RCmp(:var left, :var chain) => RAll(_recCmp(lookup, lookup.makeTypePath(left.toPath), chain)),

	ast.RLogic(left: var l, op: R_Logic.and, right: var r) => RAll(switch((_fromAST(lookup, l), _fromAST(lookup, r))) {
		(var cond, RAll(:var conds)) when (r is ast.RLogic && r.op == R_Logic.and) => [cond, ...conds],
		(var lcond, var rcond) => [lcond, rcond]
	}),

	ast.RLogic(left: var l, op: R_Logic.or, right: var r) => RAny(switch((_fromAST(lookup, l), _fromAST(lookup, r))) {
		(var cond, RAny(:var conds)) when (r is ast.RLogic && r.op == R_Logic.or) => [cond, ...conds],
		(var lcond, var rcond) => [lcond, rcond]
	}),

	ast.RLogic(left: var l, op: R_Logic.xor, right: var r) => ROne(switch((_fromAST(lookup, l), _fromAST(lookup, r))) {
		(var cond, ROne(:var conds)) when (r is ast.RLogic && r.op == R_Logic.xor) => [cond, ...conds],
		(var lcond, var rcond) => [lcond, rcond]
	}),

	ast.RLogic(left: var l, op: R_Logic.nor, right: var r) => RNot(RAny(switch((_fromAST(lookup, l), _fromAST(lookup, r))) {
		(var cond, RNot(rule: RAny(:var conds))) when (r is ast.RLogic && r.op == R_Logic.nor) => [cond, ...conds],
		(var lcond, var rcond) => [lcond, rcond]
	})),

	ast.RNot(:var rule) => RNot(_fromAST(lookup, rule)),
	ast.RParen(:var rule) => _fromAST(lookup, rule),

	_ => throw "error"
};

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

	static TypeRule fromAST(ITypeLookup lookup, ast.TypevarRule parserRule) => _fromAST(lookup, parserRule);
}