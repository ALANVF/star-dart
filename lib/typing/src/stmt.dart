import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/ast/ast.dart' as ast;
import 'package:star/text/src/span.dart';
import 'expr.dart';
import 'local.dart';
import 'pattern.dart';

part 'stmt.freezed.dart';

typedef LoopStart = ast.LoopStart;
typedef LoopStop = ast.LoopStop;

@freezed
sealed class Stmt with _$Stmt { Stmt._();
	factory Stmt.expr(Expr e) = SExpr;

	factory Stmt.ifElse(TExpr cond, TStmts then, [TStmts? orElse]) = SIf;
	factory Stmt.caseAll(List<(TExpr cond, TStmts then)> cases, [TStmts? orElse]) = SCase;
	factory Stmt.match(TExpr value, List<(TPattern pattern, TExpr? cond, TStmts then)> cases, [TStmts? orElse]) = SMatch;
	factory Stmt.matchAt(TExpr value, TPattern pattern, TExpr? cond, TStmts then, [TStmts? orElse]) = SMatchAt;

	factory Stmt.whileLoop(TExpr cond, String? label, TStmts body) = SWhile;
	factory Stmt.doWhile(TStmts body, String? label, TExpr cond) = SDoWhile;

	factory Stmt.forIn(
		TPattern lpat1, TPattern? lpat2,
		TExpr inExpr,
		TExpr? cond,
		String? label,
		TStmts body
	) = SForIn;
	factory Stmt.forRange(
		TExpr lvar, // haxe source says this should be nullable but no reasoning why????
		(LoopStart, TExpr) start,
		(LoopStop, TExpr) stop,
		TExpr? by,
		TExpr? cond,
		String? label,
		TStmts body
	) = SForRange;

	factory Stmt.recurse(List<TExpr> lvars, String? label, TStmts body) = SRecurse;

	factory Stmt.doBlock(String? label, TStmts body) = SDo;

	factory Stmt.return_(TExpr? value) = SReturn;
	factory Stmt.break_(String? depth) = SBreak;
	factory Stmt.next(String? depth, List<(String, Local, TExpr)>? withValues) = SNext;

	factory Stmt.throw_(Span span, TExpr value) = SThrow;
	factory Stmt.tryCatch(
		TStmts body,
		List<(TPattern pattern, TExpr? cond, TStmts then)> cases,
		[TStmts? orElse]
	) = STry;
}

class TStmt {
	Stmt s;
	ast.Stmt? orig;

	TStmt(this.s, [this.orig]);
}

typedef TStmts = List<TStmt>;