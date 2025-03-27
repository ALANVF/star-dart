import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'delims.dart';
import 'ident.dart';
import 'type.dart';
import 'expr.dart';
import 'stmt.dart';
import 'decl.dart';
import 'typevar.dart';

typedef OperatorSpec = ({
	Ident name,
	Type type
});

class OperatorAttrs {
	(Span, Type?)? isHidden;
	Span? isNoinherit;
	(Span, Ident?)? isNative;
	Span? isInline;
	Span? isAsm;
	Span? isMacro;
}

class Operator extends Decl implements IsGeneric {
	final Ident symbol;
	final List<Typevar> typevars;
	final Delims<OperatorSpec>? spec;
	final Type? ret;
	final OperatorAttrs attrs;
	final StmtBody? body;

	Operator(super.span, this.attrs, {
		required this.typevars,
		required this.symbol,
		required this.spec,
		required this.ret,
		required this.body
	});

	String get displayName => "operator overload";
}