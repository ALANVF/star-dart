import 'package:star/text/text.dart';

enum Priority { primary, secondary, normal }

class Info {
	final Span span;
	final String? message;
	final Priority priority;

	Info({required this.span, this.message, required this.priority});

	Info.primary({required this.span, this.message}): priority = Priority.primary;
	Info.secondary({required this.span, this.message}): priority = Priority.secondary;
	Info.normal({required this.span, this.message}): priority = Priority.normal;
}