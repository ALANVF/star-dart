// ignore_for_file: camel_case_types

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/util.dart';
import 'package:star/text/text.dart' show Span;

part 'token.freezed.dart';

typedef Tokens = List<Token>;

@freezed
sealed class StrSegment with _$StrSegment {
	factory StrSegment.str(String str) = SStr;
	factory StrSegment.char(Char char) = SChar;
	factory StrSegment.code(Tokens tokens) = SCode;

	@override String toString() => switch(this) {
		SStr(:var str) => "Str($str)",
		SChar(:var char) => "Char($char)",
		SCode(:var tokens) => "Code(" + tokens.join(", ") + ")"
	};
}

enum K {
	csep("comma"),
	comma("comma"),
	lsep("newline"),
	module("module"),
	my("my"),
	on("on"),
	return_("return"),
	init("init"),
	deinit("deinit"),
	operator("operator"),
	class_("class"),
	alias("alias"),
	type("type"),
	kind("kind"),
	category("category"),
	protocol("protocol"),
	is_("is"),
	of("of"),
	use("use"),
	has("has"),
	if_("if"),
	else_("else"),
	while_("while"),
	for_("for"),
	do_("do"),
	recurse("recurse"),
	case_("case"),
	match("match"),
	at("at"),
	break_("break"),
	next("next"),
	throw_("throw"),
	try_("try"),
	catch_("catch"),

	static("static"),
	hidden("hidden"),
	readonly("readonly"),
	friend("friend"),
	unordered("unordered"),
	getter("getter"),
	setter("setter"),
	main("main"),
	inline("inline"),
	noinherit("noinherit"),
	pattern("pattern"),
	asm("asm"),
	native("native"),
	flags("flags"),
	uncounted("uncounted"),
	strong("strong"),
	sealed("sealed"),
	macro("macro"),

	tilde("~"),
	dot("."),
	eq("="),
	eqGt("="),
	plus("+"),
	plusEq("+="),
	plusPlus("++"),
	minus("-"),
	minusEq("-="),
	minusMinus("--"),
	star("*"),
	starEq("*="),
	starStar("**"),
	starStarEq("**="),
	div("/"),
	divEq("/="),
	divDiv("//"),
	divDivEq("//="),
	mod("%"),
	modEq("%="),
	modMod("%%"),
	modModEq("%%="),
	and("&"),
	andEq("&="),
	andAnd("&&"),
	andAndEq("&&="),
	bar("|"),
	barEq("|="),
	barBar("||"),
	barBarEq("||="),
	caret("^"),
	caretEq("^="),
	caretCaret("^^"),
	caretCaretEq("^^="),
	bang("!"),
	bangEq("!="),
	bangBang("!!"),
	bangBangEq("!!="),
	question("?"),
	questionEq("?="),
	gt(">"),
	gtEq(">="),
	gtGt(">>"),
	gtGtEq(">>="),
	lt("<"),
	ltEq("<="),
	ltLt("<<"),
	ltLtEq("<<="),
	dotDotDot("..."),
	cascade("->"),

	lparen("("),
	lbracket("["),
	lbrace("{"),
	hashLParen("#("),
	hashLBracket("#["),
	hashLBrace("#{"),
	rparen(")"),
	rbracket("]"),
	rbrace("}"),

	name("name"),
	typename("typename"),
	label("label"),
	punned("punned"),
	tag("tag"),
	litsym("litsym"),

	int_("int"),
	hex("hex"),
	dec("dec"),
	str("str"),
	char("char"),
	bool_("bool"),
	this_("this"),
	wildcard("wildcard"),
	anonArg("anon arg");

	final String rep;
	
	const K(this.rep);

	bool operator <=(K other) => index <= other.index;
	bool operator >=(K other) => index >= other.index;
	K operator +(int i) => K.values[index + i];
	K operator -(int i) => K.values[index - i];
}

sealed class Token {
	final K k;
	final Span span;

	Token(this.k, this.span);

	Token asSoftName() => switch(k)
		{  K.module
		|| K.on
		|| K.init
		|| K.deinit
		|| K.operator
		|| K.class_
		|| K.alias
		|| K.type
		|| K.kind
		|| K.category
		|| K.protocol
		|| K.of
		|| K.use => TName(span, k.rep),
		_ => this
	};

	Token asAnyName() => switch(k) {
		<= K.module && <= K.catch_
		|| K.this_ => TName(span, k.rep),
		K.bool_ => TName(span, (this as TBool).b? "true" : "false"),
		_ => this
	};

	bool get isAnySep => k == K.lsep || k == K.csep || k == K.comma;
	bool get isAnyComma => k == K.csep || k == K.comma;

	@override String toString() {
		return "Token(${k.name})";
	}
}

final class TToken extends Token { TToken(super.k, super.span); }

final class TCascade extends Token {
	final int depth;
	TCascade(Span span, {required this.depth}): super(K.cascade, span);

	@override String toString() => "Cascade(depth: $depth)";
}

abstract class _TName extends Token {
	final String name;
	_TName(super.k, super.span, this.name);

	@override String toString() => this.runtimeType.toString() + "($name)";
}
final class TName     extends _TName { TName(Span span, String name): super(K.name, span, name); }
final class TTypename extends _TName { TTypename(Span span, String name): super(K.typename, span, name); }
final class TLabel    extends _TName { TLabel(Span span, String name): super(K.label, span, name); }
final class TPunned   extends _TName { TPunned(Span span, String name): super(K.name, span, name); }
final class TTag      extends _TName { TTag(Span span, String name): super(K.tag, span, name); }
final class TLitsym   extends _TName { TLitsym(Span span, String name): super(K.litsym, span, name); }

final class TInt extends Token { final int i; TInt(Span span, this.i): super(K.int_, span); @override String toString() => "Int($i)"; }
final class THex extends Token { final int h; THex(Span span, this.h): super(K.hex, span); @override String toString() => "Hex(${h.toRadixString(16)})"; }
final class TDec extends Token { final double d; TDec(Span span, this.d): super(K.dec, span); @override String toString() => "Dec($d)"; }
final class TStr extends Token {
	final List<StrSegment> segs;
	TStr(Span span, this.segs): super(K.str, span);
	
	@override String toString() {
		return "String(" + segs.join(", ") + ")";
	}
}
final class TChar extends Token { final Char c; TChar(Span span, this.c): super(K.char, span); @override String toString() => "Char($c)"; }
final class TBool extends Token { final bool b; TBool(Span span, this.b): super(K.bool_, span); @override String toString() => "Bool($b)"; }
final class TAnonArg extends Token {
	final int depth, nth;
	TAnonArg(Span span, {required this.depth, required this.nth}): super(K.anonArg, span);

	@override String toString() => "AnonArg(\$" + "."*depth +  "$nth)";
}