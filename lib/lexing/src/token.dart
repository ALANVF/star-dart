// ignore_for_file: camel_case_types

import 'package:star/util.dart';
import 'package:star/text/text.dart' show Span;

typedef Tokens = List<Token>;

sealed class StrSegment {}
final class StrSeg_Str extends StrSegment { final String str; StrSeg_Str(this.str); @override String toString() => "Str($str)"; }
final class StrSeg_Char extends StrSegment { final Char char; StrSeg_Char(this.char); @override String toString() => "Char($char)"; }
final class StrSeg_Code extends StrSegment { final Tokens tokens; StrSeg_Code(this.tokens); @override String toString() => "Code(" + tokens.join(", ") + ")"; }

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
		|| K.use => T_Name(span, k.rep),
		_ => this
	};

	Token asAnyName() => switch(k) {
		<= K.module && <= K.catch_
		|| K.this_ => T_Name(span, k.rep),
		K.bool_ => T_Name(span, (this as T_Bool).b? "true" : "false"),
		_ => this
	};

	@override String toString() {
		return "Token(${k.name})";
	}
}

final class T_Token extends Token { T_Token(super.k, super.span); }

final class T_Cascade extends Token {
	final int depth;
	T_Cascade(Span span, {required this.depth}): super(K.cascade, span);

	@override String toString() => "Cascade(depth: $depth)";
}

abstract class _T_Name extends Token {
	final String name;
	_T_Name(super.k, super.span, this.name);

	@override String toString() => this.runtimeType.toString() + "($name)";
}
final class T_Name     extends _T_Name { T_Name(Span span, String name): super(K.name, span, name); }
final class T_Typename extends _T_Name { T_Typename(Span span, String name): super(K.typename, span, name); }
final class T_Label    extends _T_Name { T_Label(Span span, String name): super(K.label, span, name); }
final class T_Punned   extends _T_Name { T_Punned(Span span, String name): super(K.name, span, name); }
final class T_Tag      extends _T_Name { T_Tag(Span span, String name): super(K.tag, span, name); }
final class T_Litsym   extends _T_Name { T_Litsym(Span span, String name): super(K.litsym, span, name); }

final class T_Int extends Token { final int i; T_Int(Span span, this.i): super(K.int_, span); @override String toString() => "Int($i)"; }
final class T_Hex extends Token { final int h; T_Hex(Span span, this.h): super(K.hex, span); @override String toString() => "Hex(${h.toRadixString(16)})"; }
final class T_Dec extends Token { final double d; T_Dec(Span span, this.d): super(K.dec, span); @override String toString() => "Dec($d)"; }
final class T_Str extends Token {
	final List<StrSegment> segs;
	T_Str(Span span, this.segs): super(K.str, span);
	
	@override String toString() {
		return "String(" + segs.join(", ") + ")";
	}
}
final class T_Char extends Token { final Char c; T_Char(Span span, this.c): super(K.char, span); @override String toString() => "Char($c)"; }
final class T_Bool extends Token { final bool b; T_Bool(Span span, this.b): super(K.bool_, span); @override String toString() => "Bool($b)"; }
final class T_AnonArg extends Token {
	final int depth, nth;
	T_AnonArg(Span span, {required this.depth, required this.nth}): super(K.anonArg, span);

	@override String toString() => "AnonArg(\$" + "."*depth +  "$nth)";
}