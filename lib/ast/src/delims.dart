import 'package:star/text/text.dart';

class Delims<T> {
	final Span begin;
	final T of;
	final Span end;

	Delims(this.begin, this.of, this.end);
}