import 'severity.dart';
import 'info.dart';

class Diagnostic {
	final Severity severity;
	final String? code;
	final String? message;
	final List<Info> info;
	
	Diagnostic({required this.severity, this.code, this.message, required this.info});

	Diagnostic.note({this.code, this.message, required this.info}): severity = Severity.note;
	Diagnostic.warning({this.code, this.message, required this.info}): severity = Severity.warning;
	Diagnostic.error({this.code, this.message, required this.info}): severity = Severity.error;
	Diagnostic.internal_error({this.code, this.message, required this.info}): severity = Severity.internal_error;
}