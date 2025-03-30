import 'dart:io';

import 'util.dart';
import 'text/text.dart';
import 'lexing/lexing.dart';
import 'reporting/reporting.dart';
import 'package:star/errors/errors.dart';
import 'ast/ast.dart';
import 'parsing/parsing.dart' as parser;

void main() {
	final src = SourceFile("./test.star");
	final renderer = DiagnosticRenderer(stdout);
	final lexer = Lexer(src);
	final (errors, tokens) = lexer.tokenize();

	print(errors);
	print(tokens);

	switch(parser.parse(tokens)) {
		case PModular(:var decls, errors: var errors2):
			errors.addAll(errors2);
			for(final decl in decls) print(prettyPrint(decl));
			

		default:
	}

	if(errors.length != 0) {
		for(final err in errors) {
			if(err is StarError) {
				final diag = err.diag;
				renderer.render(diag);
			} else {
				print('$err [not a StarError but a `${err.runtimeType}`???]');
			}
		}
	}
}
