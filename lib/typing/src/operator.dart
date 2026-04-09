import 'package:star/ast/ast.dart' as ast;
import 'package:star/ast/src/ident.dart';
import 'package:star/ast/src/ops.dart';
import 'package:star/errors/errors.dart';
import 'package:star/text/src/span.dart';
import 'package:star/util.dart';

import 'traits.dart';
import 'any_type_decl.dart';
import 'type.dart';
import 'stmt.dart';
import 'cache.dart';
import 'lookup_path.dart';
import 'type_path.dart';
import 'typevar.dart';
import 'multi_param.dart';
import 'any_method.dart';

abstract class Operator extends AnyMethod {
	Type? ret;
	Span opSpan;
	var isInline = false;
	var isMacro = false;

	Operator({
		required super.decl, required super.span,
		required this.opSpan
	});

	String get opName;

	static Operator? fromAST(ITypeLookup lookup, ast.Operator o) {
		throw "todo";
	}


	/* implements IDecl */

	String get declName => "operator overload";
}


enum UnaryOp {
	incr(""),
	decr(""),
	neg(""),
	not(""),
	compl(""),
	truthy("");

	final String rep;

	const UnaryOp(this.rep);
}

class UnaryOperator extends Operator {
	UnaryOp op;

	UnaryOperator({
		required super.decl, required super.span,
		required super.opSpan,
		required this.op
	});


	/* extends AnyMethod */

	String get methodName => op.rep;


	/* extends Operator */

	String get opName => op.rep;
}


enum BinaryOp {
	plus("+"),
	minus("-"),
	times("*"),
	pow("**"),
	div("/"),
	intDiv("//"),
	mod("%"),
	isMod("%%"),
	bitAnd("&"),
	bitOr("|"),
	bitXor("^"),
	shl("<<"),
	shr(">>"),
	eq("?="),
	ne("!="),
	gt(">"),
	ge(">="),
	lt("<"),
	le("<="),
	and("&&"),
	or("||"),
	xor("^^"),
	nor("!!");

	final String rep;

	const BinaryOp(this.rep);
}

class BinaryOperator extends Operator {
	var typevars = MultiMap<String, TypeVar>.empty();
	BinaryOp op;
	({Ident name, Type type}) param;

	BinaryOperator({
		required super.decl, required super.span,
		required super.opSpan,
		required this.op, required this.param
	});


	/* implements IErrors */
	@override
	bool hasErrors() => super.hasErrors() || typevars.allValues.any((t) => t.hasErrors());

	@override
	List<StarError> allErrors() => [
		...super.allErrors(),
		for(final t in typevars.allValues)
			...t.allErrors()
	];


	/* extends AnyMethod */

	String get methodName => op.rep;


	/* extends Operator */

	String get opName => op.rep;
}