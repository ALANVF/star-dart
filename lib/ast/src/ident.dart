import 'package:star/text/text.dart';

//typedef Ident = ({Span span, String name});

extension type Ident._((String name, Span span) i) {
	Ident(String name, Span span): i = (name, span);

	String get name => i.$1;
	Span get span => i.$2;
}