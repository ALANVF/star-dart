

import 'package:star/ast/ast.dart' show Ident;
import 'package:star/ast/ast.dart' as ast;
import 'package:star/text/src/span.dart';
import 'expr.dart';
import 'type.dart';
import 'traits.dart';
import 'type_path.dart';

typedef MultiParams = List<MultiParam>;

class MultiParam {
	Ident label;
	Ident name;
	Type type;
	ast.Expr? value;
	TExpr? tvalue = null;

	MultiParam(this.label, this.name, this.type, this.value);

	static MultiParam fromUntyped(ITypeLookup decl, ast.MultiParam param) {
		final type = decl.makeTypePath(param.type.toPath);

		switch((param.name, param.label)) {
			case (var l?, var n?): return MultiParam(l, n, type, param.value);
			case (var l?, null): return MultiParam(l, l, type, param.value);
			case (null, var n?): return MultiParam(Ident("_", n.span), n, type, param.value);
			default:
				final s = param.type.span;
				final span = Span.at(s.start, s.source);
				final ident = Ident("_", span);
				return MultiParam(ident, ident, type, param.value);
		}
	}
}