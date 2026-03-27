

import 'package:star/ast/ast.dart' show Ident;
import 'package:star/ast/ast.dart' as ast;
import 'expr.dart';
import 'type.dart';

typedef MultiParams = List<MultiParam>;

class MultiParam {
	Ident label;
	Ident name;
	Type type;
	ast.Expr? value;
	TExpr? tvalue = null;

	MultiParam(this.label, this.name, this.type, this.value);
}