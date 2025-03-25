import 'package:star/text/text.dart';

enum Severity {
	note(description: "note", color: AnsiColor.green),
	warning(description: "warning", color: AnsiColor.yellow),
	error(description: "error", color: AnsiColor.red),
	internal_error(description: "internal compiler error", color: AnsiColor.magenta);

	final String description;
	final AnsiColor color;

	const Severity({required this.description, required this.color});
}