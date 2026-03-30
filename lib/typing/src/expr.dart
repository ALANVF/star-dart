import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/src/span.dart';
import 'package:star/ast/ast.dart' as ast;
import 'package:star/ast/ast.dart' show InfixOp; // freezed shits itself without this apparently
import 'package:star/util.dart';
import 'local.dart';
import 'single_inst_kind.dart';
import 'single_static_kind.dart';
import 'operator_kind.dart';
import 'type.dart';
import 'stmt.dart';
import 'message.dart';
import 'cascade.dart';
import 'ctx.dart';
import 'pattern.dart';

part 'expr.freezed.dart';

typedef BinaryOpCandidate = (BinaryOpKind kind, TypeVarCtx? tctx);

typedef PStr = Left<String, TExpr>;
typedef PCode = Right<String, TExpr>;
typedef StrPart = Either<String, TExpr>;

typedef Prefix = ast.PrefixOp;
typedef Suffix = ast.SuffixOp;
typedef Infix<T> = ast.InfixOp<T>;
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
	factory Expr.func(List<(String name, Type? type)> params, Type? ret, TStmts body) = EFunc;
	factory Expr.anonArg(int depth, int nth) = EAnonArg;
	factory Expr.literalCtor(Type type, TExpr literal) = ELiteralCtor;

	factory Expr.paren(TExprs exprs) = EParen;
	factory Expr.block(TStmts stmts) = EBlock;

	factory Expr.typeMessage(Type type, TypeMessage msg) = ETypeMessage;
	factory Expr.typeCascade(Type type, List<TypeCascade> cascades) = ETypeCascade;
	factory Expr.typeMember(Type type, SingleStaticKind kind) = ETypeMember;

	factory Expr.objMessage(TExpr expr, ObjMessage msg) = EObjMessage;
	factory Expr.objCascade(TExpr expr, List<ObjCascade> cascades) = EObjCascade;
	factory Expr.objLazyMember(TExpr expr, String member) = EObjLazyMember;
	factory Expr.objMember(TExpr expr, SingleInstKind kind) = EObjMember;

	factory Expr.prefix(UnaryOpKind kind, TExpr right) = EPrefix;
	factory Expr.lazyPrefix(Prefix op, TExpr right) = ELazyPrefix;
	factory Expr.suffix(TExpr left, UnaryOpKind kind) = ESuffix;
	factory Expr.lazySuffix(TExpr left, Suffix op) = ELazySuffix;
	factory Expr.infix(TExpr left, List<BinaryOpCandidate> kinds, TExpr right) = EInfix;
	factory Expr.lazyInfix(TExpr left, Infix op, TExpr right) = ELazyInfix;
	factory Expr.infixChain(TExpr left, List<(List<BinaryOpCandidate> kinds, TExpr right)> chain) = EInfixChain;

	factory Expr.varDecl(String name, Type? type, TExpr? value) = EVarDecl;

	// Assignment
	factory Expr.setName(String name, Local local, TExpr value) = ESetName;
	factory Expr.destructure(Pattern pattern, TExpr value) = EDestructure;

	// From tags (subject to change)
	factory Expr.initThis(Type type, TypeMessage msg) = EInitThis;
	factory Expr.inline(TExpr expr) = EInline;
	factory Expr.kindId(TExpr expr) = EKindId;
	factory Expr.kindSlot(TExpr expr, int i) = EKindSlot;

	// Misc
	factory Expr.invalid() = EInvalid;

	// TEMP
	factory Expr.patternType(Type type) = EPatternType;
}

class TExpr {
	Expr e;
	Type? t;
	ast.Expr? orig;

	TExpr(this.e, [this.t, this.orig]);
}

typedef TExprs = List<TExpr>;