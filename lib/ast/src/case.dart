import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/text.dart';
import 'ident.dart';
import 'delims.dart';
import 'block.dart';
import 'type.dart';
import 'expr.dart';
import 'message.dart';
import 'decl.dart';
import 'method.dart';

part 'case.freezed.dart';

@freezed
sealed class CaseTag with _$CaseTag {
	factory CaseTag.single(Ident name) = CTSingle;
	factory CaseTag.multi(MultiParams params) = CTMulti;
}

@freezed
sealed class CaseKind with _$CaseKind {
	factory CaseKind.scalar(Ident name, Expr? value) = CScalar;
	factory CaseKind.tagged(Delims<CaseTag> tag, Message<Type>? assoc) = CTagged;
}

class Case extends Decl {
	final CaseKind kind;
	final Block? init;

	Case(super.span, this.kind, this.init);

	String get displayName => kind is CScalar ? "value case" : "tagged case";
}