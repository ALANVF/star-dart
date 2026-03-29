import 'package:freezed_annotation/freezed_annotation.dart';

import 'expr.dart';
import 'traits.dart';
import 'type.dart';
import 'member.dart';
import 'typevar.dart';
import 'tagged_case.dart';
import 'any_method.dart';

part 'multi_inst_kind.freezed.dart';

@freezed
sealed class MultiInstKind with _$MultiInstKind { MultiInstKind._();
	factory MultiInstKind.method(MultiStaticMethod m, Set<int>? partial) = MIMethod;
	factory MultiInstKind.member(Member m) = MIMember;
	factory MultiInstKind.fromTypevar(TypeVar tvar, String name, bool isGetter, MultiInstKind kind) = MIFromTypevar;
	factory MultiInstKind.fromParent(Type parent, MultiInstKind kind) = MIFromParent;


	Type get methodOwner => switch(this) {
		MIMethod(:var m) => m.decl.thisType,
		MIMember(:var m) => m.decl.thisType,
		MIFromTypevar(:var tvar) => tvar.thisType,
		MIFromParent(:var parent, :var kind) => throw "todo"
	};
}