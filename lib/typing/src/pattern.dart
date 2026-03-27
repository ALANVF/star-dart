import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/ast/ast.dart' as ast;
import 'expr.dart';
import 'type.dart';

part 'pattern.freezed.dart';


enum Bounds { inclusive, exclusive }

@freezed
sealed class Pattern with _$Pattern { Pattern._();
	factory Pattern.expr(TExpr expr) = PExpr;
}

class TPattern {
	Pattern p;
	Type? t;
	ast.Expr? orig;

	TPattern(this.p, [this.t, this.orig]);
}