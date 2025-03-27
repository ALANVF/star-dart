import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'ident.dart';
import 'type.dart';
import 'expr.dart';
import 'stmt.dart';
import 'decl.dart';
import 'typevar.dart';

part 'use.freezed.dart';

@freezed
sealed class UseTree with _$UseTree {
	factory UseTree.type(Type type) = UTType;
	factory UseTree.types(List<Type> types) = UTTypes;
	factory UseTree.map(List<(Type, Span, UseTree)> map) = UTMap;
}

@freezed
sealed class UseFrom with _$UseFrom {
	factory UseFrom.type(Type type) = UFType;
	factory UseFrom.file(Span span, String file) = UFFile;
}

@Freezed(copyWith: false) // fix bug where it tries generating `@pragma(...)` (which doesn't exist)
sealed class UseKind with _$UseKind { UseKind._();
	factory UseKind.import(UseTree tree, (Span, UseFrom)? from, (Span, UseTree)? as) = UImport;
	factory UseKind.pragma(Ident pragma) = UPragma;
}

class Use extends Decl implements IsGeneric {
	final List<Typevar> typevars;
	final UseKind kind;

	Use(super.span, this.kind, {
		required this.typevars
	});

	String get displayName => kind is UImport ? "import" : "pragma";
}