import 'package:star/text/src/span.dart';

import 'type.dart';

typedef LookupSeg = (Span? span, String name, List<Type> args);

extension type LookupPath(List<LookupSeg> path) {
	String get simpleName => path.map((seg) => switch(seg) {
		(_, var name, []) => name,
		(_, var name, var args) => (StringBuffer(name)
									..write("[")
									..write(args.map((t) => t.simpleName).join(", "))
									..write("]"))
									.toString()
	}).join(".");

	Span get span {
		for(var (span, _, _) in path) if(span != null) return span;

		throw "Cannot get the span of type `${simpleName}`!";
	}
}