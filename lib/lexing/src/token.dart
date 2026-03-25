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

	(K, Span) get t => (k, span);

	Token get asSoftName => switch(k)
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

	Token get asAnyName => switch(k) {
		<= K.module && <= K.catch_
		|| K.this_ => TName(span, k.rep),
		K.bool_ => TName(span, (this as TBool).b? "true" : "false"),
		_ => this
	};

	bool get isAssignableOp => switch(k)
		{  K.eq
		|| K.plusEq
		|| K.minusEq
		|| K.starEq
		|| K.starStarEq
		|| K.divEq
		|| K.divDivEq
		|| K.modEq
		|| K.modModEq
		|| K.andEq
		|| K.andAndEq
		|| K.barEq
		|| K.barBarEq
		|| K.caretEq
		|| K.caretCaretEq
		|| K.bangBangEq
		|| K.ltLtEq
		|| K.gtGtEq => true,
		_ => false
	};

	bool get isAnySep => k == K.lsep || k == K.csep || k == K.comma;
	bool get isAnyComma => k == K.csep || k == K.comma;

	@override String toString() {
		return "Token(${k.name})";
	}

	Span? get csep => k == K.csep ? span : null;
	Span? get comma => k == K.comma ? span : null;
	Span? get lsep => k == K.lsep ? span : null;
	Span? get module => k == K.module ? span : null;
	Span? get my => k == K.my ? span : null;
	Span? get on => k == K.on ? span : null;
	Span? get return_ => k == K.return_ ? span : null;
	Span? get init => k == K.init ? span : null;
	Span? get deinit => k == K.deinit ? span : null;
	Span? get operator => k == K.operator ? span : null;
	Span? get class_ => k == K.class_ ? span : null;
	Span? get alias => k == K.alias ? span : null;
	Span? get type => k == K.type ? span : null;
	Span? get kind => k == K.kind ? span : null;
	Span? get category => k == K.category ? span : null;
	Span? get protocol => k == K.protocol ? span : null;
	Span? get is_ => k == K.is_ ? span : null;
	Span? get of => k == K.of ? span : null;
	Span? get use => k == K.use ? span : null;
	Span? get has => k == K.has ? span : null;
	Span? get if_ => k == K.if_ ? span : null;
	Span? get else_ => k == K.else_ ? span : null;
	Span? get while_ => k == K.while_ ? span : null;
	Span? get for_ => k == K.for_ ? span : null;
	Span? get do_ => k == K.do_ ? span : null;
	Span? get recurse => k == K.recurse ? span : null;
	Span? get case_ => k == K.case_ ? span : null;
	Span? get match => k == K.match ? span : null;
	Span? get at => k == K.at ? span : null;
	Span? get break_ => k == K.break_ ? span : null;
	Span? get next => k == K.next ? span : null;
	Span? get throw_ => k == K.throw_ ? span : null;
	Span? get try_ => k == K.try_ ? span : null;
	Span? get catch_ => k == K.catch_ ? span : null;

	Span? get static => k == K.static ? span : null;
	Span? get hidden => k == K.hidden ? span : null;
	Span? get readonly => k == K.readonly ? span : null;
	Span? get friend => k == K.friend ? span : null;
	Span? get unordered => k == K.unordered ? span : null;
	Span? get getter => k == K.getter ? span : null;
	Span? get setter => k == K.setter ? span : null;
	Span? get main => k == K.main ? span : null;
	Span? get inline => k == K.inline ? span : null;
	Span? get noinherit => k == K.noinherit ? span : null;
	Span? get pattern => k == K.pattern ? span : null;
	Span? get asm => k == K.asm ? span : null;
	Span? get native => k == K.native ? span : null;
	Span? get flags => k == K.flags ? span : null;
	Span? get uncounted => k == K.uncounted ? span : null;
	Span? get strong => k == K.strong ? span : null;
	Span? get sealed => k == K.sealed ? span : null;
	Span? get macro => k == K.macro ? span : null;


	Span? get tilde => k == K.tilde ? span : null;
	Span? get dot => k == K.dot ? span : null;
	Span? get eq => k == K.eq ? span : null;
	Span? get eqGt => k == K.eqGt ? span : null;
	Span? get plus => k == K.plus ? span : null;
	Span? get plusEq => k == K.plusEq ? span : null;
	Span? get plusPlus => k == K.plusPlus ? span : null;
	Span? get minus => k == K.minus ? span : null;
	Span? get minusEq => k == K.minusEq ? span : null;
	Span? get minusMinus => k == K.minusMinus ? span : null;
	Span? get star => k == K.star ? span : null;
	Span? get starEq => k == K.starEq ? span : null;
	Span? get starStar => k == K.starStar ? span : null;
	Span? get starStarEq => k == K.starStarEq ? span : null;
	Span? get div => k == K.div ? span : null;
	Span? get divEq => k == K.divEq ? span : null;
	Span? get divDiv => k == K.divDiv ? span : null;
	Span? get divDivEq => k == K.divDivEq ? span : null;
	Span? get mod => k == K.mod ? span : null;
	Span? get modEq => k == K.modEq ? span : null;
	Span? get modMod => k == K.modMod ? span : null;
	Span? get modModEq => k == K.modModEq ? span : null;
	Span? get and => k == K.and ? span : null;
	Span? get andEq => k == K.andEq ? span : null;
	Span? get andAnd => k == K.andAnd ? span : null;
	Span? get andAndEq => k == K.andAndEq ? span : null;
	Span? get bar => k == K.bar ? span : null;
	Span? get barEq => k == K.barEq ? span : null;
	Span? get barBar => k == K.barBar ? span : null;
	Span? get barBarEq => k == K.barBarEq ? span : null;
	Span? get caret => k == K.caret ? span : null;
	Span? get caretEq => k == K.caretEq ? span : null;
	Span? get caretCaret => k == K.caretCaret ? span : null;
	Span? get caretCaretEq => k == K.caretCaretEq ? span : null;
	Span? get bang => k == K.bang ? span : null;
	Span? get bangEq => k == K.bangEq ? span : null;
	Span? get bangBang => k == K.bangBang ? span : null;
	Span? get bangBangEq => k == K.bangBangEq ? span : null;
	Span? get question => k == K.question ? span : null;
	Span? get questionEq => k == K.questionEq ? span : null;
	Span? get gt => k == K.gt ? span : null;
	Span? get gtEq => k == K.gtEq ? span : null;
	Span? get gtGt => k == K.gtGt ? span : null;
	Span? get gtGtEq => k == K.gtGtEq ? span : null;
	Span? get lt => k == K.lt ? span : null;
	Span? get ltEq => k == K.ltEq ? span : null;
	Span? get ltLt => k == K.ltLt ? span : null;
	Span? get ltLtEq => k == K.ltLtEq ? span : null;
	Span? get dotDotDot => k == K.dotDotDot ? span : null;

	Span? get lparen => k == K.lparen ? span : null;
	Span? get lbracket => k == K.lbracket ? span : null;
	Span? get lbrace => k == K.lbrace ? span : null;
	Span? get hashLParen => k == K.hashLParen ? span : null;
	Span? get hashLBracket => k == K.hashLBracket ? span : null;
	Span? get hashLBrace => k == K.hashLBrace ? span : null;
	Span? get rparen => k == K.rparen ? span : null;
	Span? get rbracket => k == K.rbracket ? span : null;
	Span? get rbrace => k == K.rbrace ? span : null;

	Span? get wildcard => k == K.wildcard ? span : null;
	Span? get this_ => k == K.this_ ? span : null;
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

	(Span, String) get n => (span, name);

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