import 'package:freezed_annotation/freezed_annotation.dart';

import 'expr.dart';
import 'traits.dart';
import 'type.dart';
import 'member.dart';
import 'typevar.dart';
import 'tagged_case.dart';
import 'any_method.dart';
import 'type_decl.dart';
import 'ctx.dart';

part 'member_kind.freezed.dart';

@freezed
sealed class MemberKind with _$MemberKind { MemberKind._();
	factory MemberKind.member(Member m) = MKMember;
	factory MemberKind.fromTypevar(TypeVar tvar, MemberKind kind) = MKFromTypevar;
	factory MemberKind.fromParent(Type parent, MemberKind kind) = MKFromParent;
	factory MemberKind.fromRefinee(TypeDecl ref, TypeVarCtx tctx, MemberKind kind) = MKFromRefinee;


	Type get methodOwner => switch(this) {
		MKMember(:var m) => m.decl.thisType,
		MKFromTypevar(:var tvar) => tvar.thisType,
		MKFromParent(:var parent, :var kind) => throw "todo",
		MKFromRefinee(:var ref) => ref.thisType
	};
}



/*
function getMemberOwner(self: MemberKind) return self._match(
	at(MKMember(mem)) => mem.decl.thisType,
	at(MKFromTypevar(tvar, _)) => tvar.thisType,
	at(MKFromParent(_, kind2 = MKFromParent(_, _))) => getMemberOwner(kind2),
	at(MKFromParent(parent, _)) => parent.simplify(),
	at(MKFromRefinee(ref, _, _)) => ref.thisType
);

function getMember(self: MemberKind): Member return self._match(
	at(MKMember(mem)) => mem,
	at(MKFromTypevar(_, kind2)
	 | MKFromParent(_, kind2)
	 | MKFromRefinee(_, _, kind2)) => getMember(kind2)
);

function retType(self: MemberKind): Null<Type> return self._match(
	at(MKMember(m)) => m.type,
	at(MKFromTypevar(_, _)) => null, // TODO
	at(MKFromParent(parent, kind)) => {
		retType(kind)._and(ret => {
			// TODO: make this smarter
			ret.t.match(TThis(_)) ? ret : ret.getFrom(parent.simplify());
		});
	},
	at(MKFromRefinee(ref, tctx, kind)) => retType(kind)?.getInTCtx(tctx)
);
*/