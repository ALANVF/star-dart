import 'package:freezed_annotation/freezed_annotation.dart';

import 'any_method.dart';
import 'operator.dart';
import 'typevar.dart';
import 'type.dart';
import 'ctx.dart';

part 'operator_kind.freezed.dart';


@freezed
sealed class UnaryOpKind with _$UnaryOpKind { UnaryOpKind._();
	factory UnaryOpKind.method(UnaryOperator method) = UOMethod;
	factory UnaryOpKind.fromTypevar(TypeVar tvar, UnaryOp op, UnaryOpKind kind) = UOFromTypevar;

	UnaryOperator digForMethod() => switch(this) {
		UOMethod(:var method) => method,
		UOFromTypevar(:var kind) => kind.digForMethod()
	};

	Type? get retType => switch(this) {
		UOMethod(:var method) => method.ret,
		UOFromTypevar(:var kind) => kind.retType
	};

	bool get isStep => switch(this.digForMethod().op) {
		UnaryOp.incr || UnaryOp.decr => true,
		_ => false
	};
}


@freezed
sealed class BinaryOpKind with _$BinaryOpKind { BinaryOpKind._();
	factory BinaryOpKind.method(UnaryOperator method) = BOMethod;
	factory BinaryOpKind.fromTypevar(TypeVar tvar, BinaryOp op, BinaryOpKind kind) = BOFromTypevar;

	UnaryOperator digForMethod() => switch(this) {
		BOMethod(:var method) => method,
		BOFromTypevar(:var kind) => kind.digForMethod()
	};

	Type? get retType => switch(this) {
		BOMethod(:var method) => method.ret,
		BOFromTypevar(:var kind) => kind.retType
	};

	Type get methodOwner => switch(this) {
		BOMethod(:var method) => method.decl.thisType,
		BOFromTypevar(:var kind) => kind.methodOwner
	};

}

typedef BinaryOverload = ({
	BinaryOpKind kind,
	TypeVarCtx? tctx,
	Type? argType,
	Type ret,
	bool complete
});

extension on List<BinaryOverload> {
	List<({BinaryOpKind kind, TypeVarCtx? tctx})> simplify() =>
		[for(final o in this) (kind: o.kind, tctx: o.tctx)];
}