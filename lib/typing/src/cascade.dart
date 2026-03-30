import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/src/span.dart';
import 'package:star/ast/ast.dart' as ast;
import 'package:star/ast/ast.dart' show InfixOp; // freezed shits itself without this apparently
import 'package:star/util.dart';
import 'ctx.dart';
import 'local.dart';
import 'multi_inst_kind.dart';
import 'multi_static_kind.dart';
import 'operator_kind.dart';
import 'single_inst_kind.dart';
import 'single_static_kind.dart';
import 'type.dart';
import 'expr.dart';
import 'stmt.dart';
import 'message.dart';

part 'cascade.freezed.dart';

typedef Step = ast.Step;

@freezed
sealed class Cascade<T> with _$Cascade<T> { Cascade._();
	factory Cascade.member(String mem) = CMember<T>;
	factory Cascade.assignMember(String mem, Infix<Assignable>? op, TExpr expr) = CAssignMember<T>;
	factory Cascade.assignMessage(Message<T> msg, Infix<Assignable>? op, TExpr expr) = CAssignMessage<T>;
	factory Cascade.stepMember(String mem, Step step) = CStepMember<T>;
	factory Cascade.stepMessage(Message<T> msg, Step step) = CStepMessage<T>;
	factory Cascade.block(TStmts blk) = CBlock<T>;
}


//=========================================================================================================//

typedef TypeCascadeAssignOp = ({
	TypeMessage getter,
	Infix<Assignable> op,
	List<BinaryOpKind> kinds
});

@freezed
sealed class TypeCascadeKind with _$TypeCascadeKind { TypeCascadeKind._();
	factory TypeCascadeKind.lazy(Cascade<Type> c) = TCLazy;
	factory TypeCascadeKind.member(TypeMessage mem) = TCMember;
	factory TypeCascadeKind.message(TypeMessage msg) = TCMessage;
	factory TypeCascadeKind.assignMember(TypeMessage getter, TypeCascadeAssignOp? op, TExpr expr) = TCAssignMember;
	factory TypeCascadeKind.assignMessage(TypeMessage getter, TypeCascadeAssignOp? op, TExpr expr) = TCAssignMessage;
	factory TypeCascadeKind.stepMember(MultiStaticKind setter, SingleStaticKind getter, UnaryOpKind step) = TCStepMember;
	factory TypeCascadeKind.stepMessage(MultiStaticKind setter, TypeMessage getter, UnaryOpKind step) = TCStepMessage;
	factory TypeCascadeKind.block(Ctx ctx, TStmts blk) = TCBlock;
}

typedef ObjCascadeAssignOp = ({
	ObjMessage getter,
	Infix<Assignable> op,
	List<BinaryOpKind> kinds
});

@freezed
sealed class ObjCascadeKind with _$ObjCascadeKind { ObjCascadeKind._();
	factory ObjCascadeKind.lazy(Cascade<TExpr> c) = OCLazy;
	factory ObjCascadeKind.member(ObjMessage mem) = OCMember;
	factory ObjCascadeKind.message(ObjMessage msg) = OCMessage;
	factory ObjCascadeKind.assignMember(ObjMessage getter, ObjCascadeAssignOp? op, TExpr expr) = OCAssignMember;
	factory ObjCascadeKind.assignMessage(ObjMessage getter, ObjCascadeAssignOp? op, TExpr expr) = OCAssignMessage;
	factory ObjCascadeKind.stepMember(MultiInstKind setter, SingleInstKind getter, UnaryOpKind step) = OCStepMember;
	factory ObjCascadeKind.stepMessage(MultiInstKind setter, ObjMessage getter, UnaryOpKind step) = OCStepMessage;
	factory ObjCascadeKind.block(Ctx ctx, TStmts blk) = OCBlock;
}

class CascadeOf<K> {
	Ctx ctx;
	Type? t;
	final int depth;
	final K kind;
	final List<ObjCascade> nested;

	CascadeOf({
		required this.ctx,
		required this.t,
		required this.depth,
		required this.kind,
		required this.nested
	});
}

typedef TypeCascade = CascadeOf<TypeCascadeKind>;
typedef ObjCascade = CascadeOf<ObjCascadeKind>;