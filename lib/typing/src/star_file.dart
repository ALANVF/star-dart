import 'package:star/ast/src/program.dart';
import 'package:star/errors/errors.dart';
import 'package:star/text/src/source_file.dart';
import 'star_dir.dart';
import 'star_unit.dart';
import 'traits.dart';
import 'import.dart';
import 'type.dart';
import 'type_decl.dart';
import 'category.dart';

sealed class StarFile implements ITypeLookup, IErrors {
	final errors = <StarError>[];
	final StarDir dir;
	final String path;
	StarUnit? unit;
	late SourceFile source;
	Program? program = null;
	bool status = false;
	final imports = <Import>[];
	final imported = <(ITypeLookup from, List<Type> types)>[];
	final decls = <String, List<TypeDecl>>{};
	final sortedDecls = <TypeDecl>[];
	final categories = <Category>[];

	StarFile(this.dir, this.path, [this.unit]);

	void initSource() {
		source = SourceFile(path);
	}
}
