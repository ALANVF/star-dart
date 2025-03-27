import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/util.dart';
import 'stmt.dart';
import 'decl.dart';
import 'package:star/errors/errors.dart';

part 'program.freezed.dart';

typedef ScriptDecl = Either<Decl, Stmt>;

@Freezed(makeCollectionsUnmodifiable: false)
sealed class Program with _$Program {
	final List<StarError> errors;

	Program._({required this.errors});

	factory Program.modular(List<Decl> decls, {required List<StarError> errors}) = PModular;
	factory Program.script(List<ScriptDecl> decls, {required List<StarError> errors}) = PScript;
}