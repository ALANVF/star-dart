import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'ident.dart';
import 'block.dart';
import 'stmt.dart';
import 'ops.dart';
import 'message.dart';
import 'cascade.dart';

part 'expr.freezed.dart';

typedef StrPart = Either<String, Expr>;

@freezed
sealed class Expr with _$Expr { Expr._();
	factory Expr.name(Ident name) = EName;
	factory Expr.litsym(Ident name) = ELitsym;

	factory Expr.tag(Ident name, Expr expr) = ETag;
	
	factory Expr.int(Span span, int value) = EInt;
	factory Expr.dec(Span span, double value) = EDec;
	factory Expr.char(Span span, Char value) = EChar;
	factory Expr.str(Span span, List<StrPart> parts) = EStr;
	factory Expr.bool(Span span, bool value) = EBool;
	factory Expr.array(Span begin, List<Expr> array, Span end) = EArray;
	factory Expr.hash(Span begin, List<(Expr, Expr)> hash, Span end) = EHash;
	factory Expr.tuple(Span begin, List<Expr> tuple, Span end) = ETuple;
	factory Expr.this_kw(Span span) = EThis;
	factory Expr.wildcard(Span span) = EWildcard;
	factory Expr.func(
		Span begin,
		List<(Ident, Type?)> params,
		Type? ret,
		List<Stmt> body,
		Span end
	) = EFunc;
	factory Expr.anonArg(Span span, int nth, int depth) = EAnonArg;
	factory Expr.literalCtor(Type type, Expr literal) = ELiteralCtor;

	factory Expr.paren(Span begin, List<Expr> paren, Span end) = EParen;
	factory Expr.block(Block block) = EBlock;

	factory Expr.typeMsg(Type type, Span begin, Message<Type> message, Span end) = ETypeMessage;
	factory Expr.typeCascades(Type type, List<Cascade<Type>> cascades) = ETypeCascades;
	factory Expr.typeMember(Type type, Ident member) = ETypeMember;

	factory Expr.exprMsg(Expr expr, Span begin, Message<Expr> message, Span end) = EExprMessage;
	factory Expr.exprCascades(Expr expr, List<Cascade<Expr>> cascades) = EExprCascades;
	factory Expr.exprMember(Expr expr, Ident member) = EExprMember;

	factory Expr.prefix(Span span, PrefixOp op, Expr right) = EPrefix;
	factory Expr.suffix(Expr left, Span span, SuffixOp op) = ESuffix;
	factory Expr.infix(Expr left, Span span, InfixOp op, Expr right) = EInfix;

	factory Expr.varDecl(Span span, Ident name, Type? type, Expr? value) = EVarDecl;

	// maybe remove
	factory Expr.type(Type type) = EType;


	Span get mainSpan => throw "todo";
}