import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/ast/ast.dart' as ast;
import 'expr.dart';
import 'traits.dart';
import 'type.dart';
import 'member.dart';
import 'typevar.dart';
import 'any_method.dart';
import 'tagged_case.dart';
import 'value_case.dart';

part 'single_static_kind.freezed.dart';

@freezed
sealed class SingleStaticKind with _$SingleStaticKind { SingleStaticKind._();
	factory SingleStaticKind.method(SingleStaticMethod m) = SSMethod;
	factory SingleStaticKind.multiMethod(MultiStaticMethod m) = SSMultiMethod;
	factory SingleStaticKind.init(SingleInit i) = SSInit;
	factory SingleStaticKind.multiInit(MultiInit i) = SSMultiInit;
	factory SingleStaticKind.member(Member m) = SSMember;
	factory SingleStaticKind.taggedCase(SingleTaggedCase c) = SSTaggedCase;
	factory SingleStaticKind.taggedCaseAlias(TaggedCase c) = SSTaggedCaseAlias;
	factory SingleStaticKind.valueCase(ValueCase c) = SSValueCase;
	factory SingleStaticKind.fromTypevar(TypeVar tvar, String name, bool isGetter, SingleStaticKind kind) = SSFromTypevar;
	factory SingleStaticKind.fromParent(Type parent, SingleStaticKind kind) = SSFromParent;

	
	String get baseName => switch(this) {
		SSMethod(:var m) => m.name.name,
		SSMultiMethod(:var m) => m.params.firstWhere((p) => p.value == null, orElse: () => m.params[0]).label.name,
		SSInit(:var i) => i.name.name,
		SSMultiInit(:var i) => i.params.firstWhere((p) => p.value == null, orElse: () => i.params[0]).label.name,
		SSMember(:var m) => m.name.name,
		SSTaggedCase(:var c) => c.name.name, // dart is marking this as unreachable??
		SSTaggedCaseAlias(:var c) => switch(c.assoc!) {
			ast.MSingle(:var name) => name.name,
			_ => throw ""
		},
		SSValueCase(:var c) => c.name.name,
		SSFromTypevar(:var name) => name,
		SSFromParent(:var kind) => kind.baseName
	};

	Type? get retType => throw "TODO";
}


/*
function retType(self: SingleStaticKind): Null<Type> return self._match(
	at(SSMethod(m)) => m.ret ?? Pass2.STD_Void.thisType,
	at(SSMultiMethod(m)) => m.ret ?? Pass2.STD_Void.thisType,
	at(SSInit({decl: d}) | SSMultiInit({decl: d})
	 | SSTaggedCase({decl: d}) | SSTaggedCaseAlias({decl: d})
	 | SSValueCase({decl: d})) => {t: TThis(d), span: null},
	at(SSMember(m)) => m.type,
	at(SSFromTypevar(_, _, _, _)) => null, // TODO
	at(SSFromParent(parent, kind)) => {
		retType(kind)._and(ret => {
			// TODO: make this smarter
			ret.t.match(TThis(_)) ? ret : ret.getFrom(parent.simplify());
		});
	}
);
*/