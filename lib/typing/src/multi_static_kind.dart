import 'package:freezed_annotation/freezed_annotation.dart';

import 'expr.dart';
import 'traits.dart';
import 'type.dart';
import 'member.dart';
import 'typevar.dart';
import 'tagged_case.dart';
import 'any_method.dart';

part 'multi_static_kind.freezed.dart';

@freezed
sealed class MultiStaticKind with _$MultiStaticKind { MultiStaticKind._();
	factory MultiStaticKind.method(MultiStaticMethod m, Set<int>? partial) = MSMethod;
	factory MultiStaticKind.init(MultiInit i, Set<int>? partial) = MSInit;
	factory MultiStaticKind.memberwiseInit(List<Member> ms) = MSMemberwiseInit;
	factory MultiStaticKind.member(Member m) = MSMember;
	factory MultiStaticKind.taggedCase(List<Member> ms1, MultiTaggedCase c, List<Member> ms2, Set<int>? partial) = MSTaggedCase;
	factory MultiStaticKind.taggedCaseAlias(TaggedCase c) = MSTaggedCaseAlias;
	factory MultiStaticKind.fromTypevar(TypeVar tvar, String name, bool isGetter, MultiStaticKind kind) = MSFromTypevar;
	factory MultiStaticKind.fromParent(Type parent, MultiStaticKind kind) = MSFromParent;


	Type get methodOwner => switch(this) {
		MSMethod(:var m) => m.decl.thisType,
		MSInit(:var i) => i.decl.thisType,
		MSMemberwiseInit(:var ms) => ms.first.decl.thisType,
		MSMember(:var m) => m.decl.thisType,
		MSTaggedCase(:var c) => c.decl.thisType,
		MSTaggedCaseAlias(:var c) => c.decl.thisType,
		MSFromTypevar(:var tvar) => tvar.thisType,
		MSFromParent(:var parent, :var kind) => throw "todo"
	};
}

/*

function getMethodOwner(kind: MultiStaticKind) return kind._match(
	at(MSMethod(mth, _)) => mth.decl.thisType,
	at(MSInit(init, _)) => init.decl.thisType,
	at(MSMemberwiseInit(ms)) => ms[0].decl.thisType,
	at(MSMember(mem)) => mem.decl.thisType,
	at(MSTaggedCase(_, (_ : TaggedCase) => c, _) | MSTaggedCaseAlias(c)) => c.decl.thisType,
	at(MSFromTypevar(tvar, _, _, _)) => tvar.thisType,
	at(MSFromParent(_, kind2 = MSFromParent(_, _))) => getMethodOwner(kind2),
	at(MSFromParent(parent, _)) => parent.simplify()
);
*/