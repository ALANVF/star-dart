import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'delims.dart';
import 'ident.dart';
import 'type.dart';
import 'expr.dart';
import 'stmt.dart';
import 'decl.dart';
import 'typevar.dart';
import 'method.dart';

class InitAttrs {
	(Span, Type?)? isHidden;
	Span? isNoinherit;
	Span? isUnordered;
	(Span, Ident?)? isNative;
	Span? isAsm;
	Span? isMacro;
}

class Init extends Decl implements IsGeneric {
	final List<Typevar> typevars;
	final Delims<MethodKind> spec;
	final InitAttrs attrs;
	final StmtBody? body;

	Init(super.span, this.attrs, {
		required this.typevars,
		required this.spec,
		required this.body
	});

	String get displayName => "initializer";
}