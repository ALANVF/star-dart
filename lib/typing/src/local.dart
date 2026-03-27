

import 'package:star/text/src/span.dart';
import 'ctx.dart';
import 'expr.dart';
import 'type.dart';

abstract class Local {
	Ctx ctx;
	Span span;
	String name;
	Type? type;
	TExpr? expr;

	Local({
		required this.ctx,
		required this.span,
		required this.name,
		required this.type,
		required this.expr
	});
}