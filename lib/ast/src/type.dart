import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/text.dart';
import 'delims.dart';
import 'ident.dart';

part 'type.freezed.dart';

sealed class Type {
	Type();

	factory Type.path(List<TypeSeg> segs, List<Span>? leading) => Type_Path(segs, leading);
	factory Type.blank(Span blank, [TypeArgs? args]) => Type_Blank(blank, args);

	Span get span;

	String get simpleName;

	int get depth;
}

class Type_Path extends Type {
	final List<TypeSeg> segs;
	final List<Span>? leading;

	Type_Path(this.segs, [this.leading]);

	Span get span => Span.range(leading?[0] ?? segs[0].span, segs.last.span);

	String get simpleName => ("_." * (leading?.length ?? 0)) + segs.map((s) => s.simpleName).join(".");

	int get depth => leading?.length ?? 0;
}

class Type_Blank extends Type {
	final Span blank;
	final TypeArgs? args;

	Type_Blank(this.blank, [this.args]);

	Span get span => args == null ? blank : Span.range(blank, args!.end);

	String get simpleName {
		if(args == null) {
			return "_";
		} else {
			return "_[" + ("..., " * (args!.of.length - 1)) + "...]";
		}
	}

	int get depth => 0;
}

class TypeSeg {
	final Ident name;
	final TypeArgs? args;

	TypeSeg(this.name, [this.args]);

	Span get span => args == null ? name.span : Span.range(name.span, args!.end);

	String get simpleName {
		if(args == null) {
			return "_";
		} else {
			return "_[" + ("..., " * (args!.of.length - 1)) + "...]";
		}
	}
}

typedef TypeArgs = Delims<List<Type>>;
typedef TypeParams = TypeArgs;

@freezed
sealed class TypeSpec with _$TypeSpec { TypeSpec._();
	factory TypeSpec.one(Type type) = OneType;
	factory TypeSpec.many(Span begin, List<Type> types, Span end) = ManyTypes;

	Span get span => switch(this) {
		OneType(:var type) => type.span,
		ManyTypes(:var begin, :var end) => Span.range(begin, end)
	};
}