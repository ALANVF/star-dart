import 'package:star/text/text.dart';
import 'stmt.dart';

typedef Block = ({
	Span begin,
	List<Stmt> stmts,
	Span end
});