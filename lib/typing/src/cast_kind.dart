import 'package:freezed_annotation/freezed_annotation.dart';

import 'ctx.dart';
import 'expr.dart';
import 'traits.dart';
import 'type.dart';
import 'member.dart';
import 'typevar.dart';
import 'tagged_case.dart';
import 'any_method.dart';

part 'cast_kind.freezed.dart';

@freezed
sealed class CastKind with _$CastKind { CastKind._();
	factory CastKind.method(CastMethod m, TypeVarCtx? tctx) = CIMethod;
	factory CastKind.upcast(Type parent) = CIUpcast;
	factory CastKind.downcast(Type child) = CIDowncast;
	factory CastKind.native(Type t) = CINative;
	factory CastKind.fromTypevar(TypeVar tvar, Type target, CastKind kind) = CIFromTypevar;
	//factory CastKind.fromParent(Type parent, CastKind kind) = CIFromParent;
}

/*
enum CastKind {
	CMethod(m: CastMethod, ?tctx: TypeVarCtx);
	CUpcast(parent: Type);
	CDowncast(child: Type);
	CNative(t: Type);

	CFromTypevar(tvar: TypeVar, target: Type, kind: CastKind);
}
*/