import 'package:star/ast/src/program.dart';
import 'package:star/errors/errors.dart';
import 'package:star/text/src/source_file.dart';
import 'package:star/typing/src/any_type_decl.dart';
import 'package:star/typing/src/cache.dart';
import 'package:star/typing/src/ctx.dart';
import 'package:star/typing/src/lookup_path.dart';
import 'package:star/typing/src/type_path.dart';
import 'package:star/util.dart';
import 'package:star/lexing/lexing.dart';
import 'package:star/parsing/parsing.dart' as parser;
import 'package:star/ast/ast.dart' as ast;

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

	void parse() {
		final (diags, tokens) = Lexer(source).tokenize();
		errors.addAll(diags);
		
		final result = parser.parse(tokens);

		switch(result) {
			case ast.PModular(errors: []) || ast.PScript(errors: []):
				status = diags.isEmpty;
			
			case ast.PModular(:var errors) || ast.PScript(:var errors):
				for(final (i, error) in errors.indexed) {
					this.errors.add(error);

					if(i == 25) {
						this.errors.add(StarError.tooManyErrors());
						break;
					}
				}
		}

		program = result;
	}

	/*
	function buildImports() {
		program.forEach(prog -> {
			final decls = switch prog {
				case Modular(_, decls2): decls2;
				case Script(_, decls2): decls2.filterMap(decl -> switch decl {
					case SDecl(decl2): decl2;
					default: null;
				});
			};
			var lastWasUse = true;

			for(decl in decls) switch decl {
				case DUse({span: span, kind: kind, generics: typevars}):
					if(!lastWasUse) {
						lastWasUse = true;
						errors.push(Type_UnorganizedCode(span));
					}

					if(typevars != Nil) {
						throw "NYI!";
					}

					switch kind {
					case Import(spec, from, as):
						imports.push({
							span: span,
							spec: spec,
							from: Option.fromNull(from),
							as: as._andOr(a => Some(a._2), None)
						});
					
					case Pragma(span2, pragma):
						status = false;
						errors.push(Type_UnknownPragma(pragma, span2));
						continue;
					}

				default: if(lastWasUse) lastWasUse = false;
			}
		});
	}*/



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