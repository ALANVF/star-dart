import 'package:star/ast/ast.dart' as ast;
import 'package:star/text/src/span.dart';
import 'package:star/util.dart';
import 'typevar.dart';

typedef ImportFrom = ast.UseFrom;
typedef ImportTree = ast.UseTree;

class Import {
	final typevars = MultiMap<String, TypeVar>.empty();
	final Span span;
	final ImportTree spec;
	final ImportFrom? from;
	final ImportTree? as;

	Import(this.span, this.spec, {this.from, this.as});
}