import 'dart:io';

import 'text/text.dart';
import 'lexing/lexing.dart';
import 'reporting/reporting.dart';
import 'package:star/errors/errors.dart';

void main() {
	final src = SourceFile("./test.star");
	final renderer = DiagnosticRenderer(stdout);
	final lexer = Lexer(src);
	final (errors, tokens) = lexer.tokenize();

	print(errors);
	print(tokens);

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
