import 'package:star/ast/src/program.dart';
import 'package:star/errors/errors.dart';
import 'package:star/text/src/source_file.dart';
import 'package:star/typing/src/any_type_decl.dart';
import 'package:star/typing/src/cache.dart';
import 'package:star/typing/src/ctx.dart';
import 'package:star/typing/src/lookup_path.dart';
import 'package:star/typing/src/type_path.dart';
import 'package:star/util.dart';

import 'star_dir.dart';
import 'star_unit.dart';
import 'traits.dart';
import 'import.dart';
import 'type.dart';
import 'type_decl.dart';
import 'category.dart';

class StarFile implements ITypeLookup, IErrors {
	final errors = <StarError>[];
	final StarDir dir;
	final String path;
	StarUnit? unit;
	late SourceFile source;
	Program? program = null;
	bool status = false;
	final imports = <Import>[];
	final imported = <(ITypeLookup from, List<Type> types)>[];
	final decls = MultiMap<String, TypeDecl>.empty();
	final sortedDecls = <TypeDecl>[];
	final categories = <Category>[];

	StarFile(this.dir, this.path, [this.unit]);

	void initSource() {
		source = SourceFile(path);
	}

	void addTypeDecl(TypeDecl decl) {
		decls.add(decl.name.name, decl);
		sortedDecls.add(decl);
	}


	/* implements IErrors */

	bool hasErrors() =>
		(  !status
		|| errors.isNotEmpty
		|| sortedDecls.any((d) => d.hasErrors())
		|| categories.any((c) => c.hasErrors()));

	List<StarError> allErrors() => [
		...errors,
		for(final d in sortedDecls) ...d.allErrors(),
		for(final c in categories) ...c.allErrors()
	];


	/* implements ILookupDecl */

	Type makeTypePath(TypePath path) => path.toType(this);
	
	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) => throw "todo";
	
	Category? findCategory(Ctx ctx, Type cat, Type forType, AnyTypeDecl? from, [Cache cache = const Cache.empty()]) => throw "todo";
}