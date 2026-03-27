import '../../text/src/span.dart';
import '../../ast/ast.dart' as ast;

import 'lookup_path.dart';
import 'traits.dart';

extension type TypePath._(ast.Type type) {
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
	
	/*
	static function toType(self: TypePath, lookup: ITypeLookup): Type {
		return switch self {
			case TBlank(span): {t: TBlank, span: span};
			case TBlankParams(span, {of: params}):
				{
					t: TApplied({t: TBlank, span: span}, params.map(p -> toType(p, lookup))),
					span: self.span()
				};
			case TSegs(_, Nil): throw "error!";
			case TSegs(leading, segs):
				{
					t: TPath(leading.length(), rec(segs, lookup), lookup),
					span: self.span()
				};
		};
	}
	*/
}