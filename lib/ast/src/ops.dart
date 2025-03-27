import 'package:star/text/text.dart';

abstract class Assignable {}
enum InfixOp<T> {
	eq, ne, gt, ge, lt, le,
	plus<Assignable>(),
	minus<Assignable>(),
	times<Assignable>(),
	pow<Assignable>(),
	div<Assignable>(),
	intDiv<Assignable>(),
	mod<Assignable>(),
	isMod<Assignable>(),
	bitAnd<Assignable>(),
	bitOr<Assignable>(),
	bitXor<Assignable>(),
	shl<Assignable>(),
	shr<Assignable>(),
	and<Assignable>(),
	or<Assignable>(),
	xor<Assignable>(),
	nor<Assignable>()
}

enum SuffixOp {
	incr, decr, truthy;
}

enum PrefixOp {
	incr, decr, neg, not, compl, spread;
}