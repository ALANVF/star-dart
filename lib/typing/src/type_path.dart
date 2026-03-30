import '../../text/src/span.dart';
import '../../ast/ast.dart' as ast;

import 'lookup_path.dart';
import 'traits.dart';
import 'type.dart';

extension type TypePath(ast.Type type) {
	static List<LookupSeg> _mapSegs(List<ast.TypeSeg> segs, ITypeLookup lookup) => switch(segs) {
		[] => [],
		[ast.TypeSeg(:var span, :var name, args: null || []), ...var rest] => [(span, name.name, []), ..._mapSegs(rest, lookup)],
		[ast.TypeSeg(:var span, :var name, :var args!), ...var rest] => [
			(Span.range(span, args.end), name.name, [for(var p in args.of) lookup.makeTypePath(p as TypePath)]),
			..._mapSegs(rest, lookup)
		]
	};

	(int depth, LookupPath path) toLookupPath(ITypeLookup lookup) => switch(type) {
		ast.Type_Blank _ => throw "error",
		ast.Type_Path(:var leading, :var segs) => (
			leading?.length ?? 0,
			_mapSegs(segs, lookup) as LookupPath
		)
	};

	Type toType(ITypeLookup lookup) => switch(type) {
		ast.Type_Blank(:var blank, args: null) => Type.blank(span: blank),
		ast.Type_Blank(:var blank, :var args!) => Type.applied(
			Type.blank(span: blank),
			[for(final a in args.of) TypePath(a).toType(lookup)]
		),
		ast.Type_Path(segs: []) => throw "error!",
		ast.Type_Path(:var leading, :var segs) => Type.path(
			leading?.length ?? 0,
			LookupPath(_mapSegs(segs, lookup)),
			lookup,
			span: type.span
		)
	};
}