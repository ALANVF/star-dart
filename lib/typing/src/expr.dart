import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/src/span.dart';
import 'package:star/ast/ast.dart' as ast;
import 'package:star/util.dart';
import 'local.dart';
import 'type.dart';
import 'stmt.dart';

part 'expr.freezed.dart';

typedef PStr = Left<String, TExpr>;
typedef PCode = Right<String, TExpr>;
typedef StrPart = Either<String, TExpr>;

typedef Prefix = ast.PrefixOp;
typedef Suffix = ast.SuffixOp;
typedef Infix = ast.InfixOp;
typedef Assignable = ast.Assignable;

@freezed
sealed class Expr with _$Expr { Expr._();
	factory Expr.local(String name, Local local) = ELocal;

	factory Expr.tag(String tag, TExpr expr) = ETag;

	factory Expr.int(int i) = EInt;
	factory Expr.dec(double d) = EDec;
	factory Expr.char(Char c) = EChar;
	factory Expr.str(List<StrPart> parts) = EStr;
	factory Expr.bool(bool b) = EBool;
	factory Expr.array(TExprs values) = EArray;
	factory Expr.dict(List<(TExpr k, TExpr v)> pairs) = EDict;
	factory Expr.tuple(TExprs values) = ETuple;
	factory Expr.this_() = EThis;
	factory Expr.wildcard() = EWildcard;
	//func
	factory Expr.anonArg(int depth, int nth) = EAnonArg;
	factory Expr.literalCtor(Type type, TExpr literal) = ELiteralCtor;

	factory Expr.paren(TExprs exprs) = EParen;
	factory Expr.block(TStmts stmts) = EBlock;

}

sealed class TExpr {
	Expr e;
	Type? t;
	ast.Expr? orig;

	TExpr(this.e, [this.t, this.orig]);
}

typedef TExprs = List<TExpr>;