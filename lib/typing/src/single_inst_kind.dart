import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/ast/ast.dart' as ast;
import 'expr.dart';
import 'traits.dart';
import 'type.dart';
import 'member.dart';
import 'typevar.dart';
import 'any_method.dart';

part 'single_inst_kind.freezed.dart';

@freezed
sealed class SingleInstKind with _$SingleInstKind { SingleInstKind._();
	factory SingleInstKind.method(SingleMethod m) = SIMethod;
	factory SingleInstKind.multiMethod(MultiMethod m) = SIMultiMethod;
	factory SingleInstKind.member(Member m) = SIMember;
	factory SingleInstKind.fromTypevar(TypeVar tvar, String name, bool isGetter, SingleInstKind kind) = SIFromTypevar;
	factory SingleInstKind.fromParent(Type parent, SingleInstKind kind) = SIFromParent;

	
	String get baseName => switch(this) {
		SIMethod(:var m) => m.name.name,
		SIMultiMethod(:var m) => m.params.firstWhere((p) => p.value == null, orElse: () => m.params[0]).label.name,
		SIMember(:var m) => m.name.name,
		SIFromTypevar(:var name) => name,
		SIFromParent(:var kind) => kind.baseName
	};

	Type? get retType => throw "TODO";
}