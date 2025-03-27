// ignore_for_file: unreachable_switch_case

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'ident.dart';
import 'block.dart';
import 'expr.dart';

part 'stmt.freezed.dart';

enum LoopStart { from, after }
enum LoopStop { to, upto, downto, times }

@freezed
sealed class Then with _$Then { Then._();
	factory Then.block(Block block) = ThenBlock;
	factory Then.stmt(Stmt stmt) = ThenStmt;

	List<Stmt> get stmts => switch(this) {
		ThenBlock(:var block) => block.stmts,
		ThenStmt(:var stmt) => [stmt]
	};
}

typedef StmtBody = Then;

typedef PatternAt = ({
	Span span,
	Expr pattern,
	Expr? cond,
	Then then
});

typedef CaseAt = ({
	Span span,
	Expr cond,
	Then then
});

@freezed
sealed class Stmt with _$Stmt { Stmt._();
	factory Stmt.expr(Expr expr) = SExpr;

	factory Stmt.ifElse(
		Span span, Expr cond,
		Then then,
		(Span, Block)? elseBlk
	) = SIfElse;

	factory Stmt.cases(
		Span span,
		List<CaseAt> cases,
		(Span, Then) elseBlk
	) = SCase;

	factory Stmt.match(
		Span span,
		Expr value,
		List<PatternAt> cases,
		(Span, Then) elseBlk
	) = SMatch;

	factory Stmt.matchAt(
		Span span, Expr value,
		(Span, Expr) at,
		(Span, Expr)? cond,
		Then then,
		(Span, Block)? elseBlk
	) = SMatchAt;

	factory Stmt.whileLoop(
		Span span, Expr cond,
		(Span, Ident)? label,
		Then then,
	) = SWhile;

	factory Stmt.doWhile(
		Span span,
		(Span, Ident)? label,
		Block block,
		Span span2, Expr cond
	) = SDoWhile;

	factory Stmt.forIn(
		Span span,
		Expr var1, Expr? var2,
		(Span, Expr) value,
		(Span, Expr)? whileCond,
		(Span, Ident)? label,
		Then then,
	) = SForIn;

	factory Stmt.forRange(
		Span span,
		Expr var1,
		LoopStart start,
		LoopStop stop,
		(Span, Expr)? whileCond,
		(Span, Ident)? label,
		Then then,
	) = SForRange;

	factory Stmt.recurse(
		Span span,
		List<Expr> lvars, // rly it's just var decls, but we need to allow existing vars too
		(Span, Ident)? label,
		Then then
	) = SRecurse;

	factory Stmt.doBlock(
		Span span,
		(Span, Ident)? label,
		Block block
	) = SDo;

	factory Stmt.returnStmt(Span span, Expr? value) = SReturn;
	factory Stmt.breakStmt(Span span, Ident? label) = SBreak;
	factory Stmt.nextStmt(Span span, Ident? label, List<Expr>? withValues) = SNext;
	factory Stmt.throwStmt(Span span, Expr? expr) = SThrow;

	factory Stmt.tryCatch(
		Span span, Block tryBlk,
		Span span2,
		List<PatternAt> cases,
		(Span, Then)? elseBlk
	) = STry;
}