import 'package:star/ast/ast.dart' show Ident;
import 'package:star/text/src/span.dart';

import 'traits.dart';
import 'errors.dart';
import 'type.dart';

abstract class AnyTypeDecl implements ITypeable, ITypeLookupDecl {
	final errors = <StarError>[];
	Span span;
	Ident name;
	ITypeLookup lookup;
	late Type thisType;

	AnyTypeDecl({
		required this.span,
		required this.name,
		required this.lookup
	});
}

abstract class AnyFullTypeDecl extends AnyTypeDecl {
	List<Type> params;

	AnyFullTypeDecl({
		required super.span,
		required super.name,
		required this.params,
		required super.lookup,
	});
}