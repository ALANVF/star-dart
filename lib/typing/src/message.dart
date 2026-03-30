import 'package:freezed_annotation/freezed_annotation.dart';

import 'cast_kind.dart';
import 'expr.dart';
import 'multi_inst_kind.dart';
import 'single_inst_kind.dart';
import 'type.dart';
import 'single_static_kind.dart';
import 'multi_static_kind.dart';
import 'ctx.dart';

part 'message.freezed.dart';

@freezed
sealed class Message<T> with _$Message<T> {
	final Type? category;

	Message._({required this.category});
	
	factory Message.single(String name, {required Type? category}) = MSingle<T>;
	factory Message.multi(List<String> labels, TExprs exprs, {required Type? category}) = MMulti<T>;
	static Message<TExpr> cast(Type type, {required Type? category}) => MCast(type, category: category);
}

class MCast extends Message<TExpr> {
	final Type type;
	MCast(this.type, {required Type? category}): super._(category: category);
}


typedef TypeMultiCandidate = (MultiStaticKind kind, TypeVarCtx? tctx);

@freezed
sealed class TypeMessage with _$TypeMessage { TypeMessage._();
	factory TypeMessage.single(SingleStaticKind kind) = TMSingle;
	factory TypeMessage.multi(List<TypeMultiCandidate> candidates, List<String> labels, List<TExpr> args) = TMMulti;
	factory TypeMessage.super_(Type parent, TypeMessage msg) = TMSuper;
}

typedef ObjMultiCandidate = (MultiInstKind kind, TypeVarCtx? tctx);

@freezed
sealed class ObjMessage with _$ObjMessage { ObjMessage._();
	factory ObjMessage.lazy(Message<TExpr> msg) = OMLazy;
	factory ObjMessage.single(SingleInstKind kind) = OMSingle;
	factory ObjMessage.multi(List<ObjMultiCandidate> candidates, List<String> labels, List<TExpr> args) = OMMulti;
	factory ObjMessage.cast(Type target, List<CastKind> candidates) = OMCast;
	factory ObjMessage.super_(Type parent, ObjMessage msg) = OMSuper;
}