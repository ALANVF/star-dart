import 'package:star/util.dart';
import 'package:star/text/text.dart' show Cursor;

typedef Charset = Set<Char>;

class Reader {
	final cursor = Cursor();
	final String input;
	final int length;
	var offset = 0;

	Reader(this.input): length = input.length;

	bool get hasNext => offset < length;
	bool hasNextAt(int index) => offset + index < length;

	Char unsafePeek() => input.charAt(offset);
	Char unsafePeekAt(int index) => input.charAt(offset + index);
	bool unsafePeekChar(Char char) => input.charAt(offset) == char;

	Char? peek() => hasNext? unsafePeek() : null;
	bool peekChar(Char char) => hasNext && unsafePeekChar(char);
	bool peekString(String str) => str.startsWith(str, offset);
	bool peekCharset(Charset charset) => hasNext && charset[unsafePeek()];

	Char? peekAt(int index) => hasNext? unsafePeekAt(index) : null;
	bool peekCharAt(int index, Char char) => hasNextAt(index) && unsafePeekAt(index) == char;
	bool peekStringAt(int index, String str) => hasNextAt(index) && str.startsWith(str, offset + index);
	bool peekCharsetAt(int index, Charset charset) => hasNextAt(index) && charset[unsafePeekAt(index)];

	bool peekNotChar(Char char) => !hasNext || !unsafePeekChar(char);
	bool peekNotString(String str) => !str.startsWith(str, offset);
	bool peekNotCharset(Charset charset) => !hasNext || !charset[unsafePeek()];
	
	bool peekNotCharsetAt(int index, Charset charset) => !hasNextAt(index) || !charset[unsafePeekAt(index)];

	Char eat() {
		final char = unsafePeek();

		offset++;
		cursor.appendChar(char);

		return char;
	}
	bool eatChar(Char char) {
		if(peekChar(char)) {
			offset++;
			cursor.appendChar(char);
			return true;
		} else {
			return false;
		}
	}
	bool eatString(String str) {
		if(peekString(str)) {
			offset += str.length;
			cursor.append(str);
			return true;
		} else {
			return false;
		}
	}

	void safeNext() {
		if(hasNext) {
			cursor.appendChar(unsafePeek());
			offset++;
		}
	}

	void next() {
		cursor.appendChar(unsafePeek());
		offset++;
	}

	void nextN(int n) {
		for(final _ in n.times()) {
			cursor.appendChar(unsafePeek());
			offset++;
		}
	}

	String substring(int start, [int? end]) {
		return input.substring(start, end ?? offset);
	}

	bool peekDigit() => hasNext && switch(unsafePeek()) {
		>= Char.ZERO && <= Char.NINE => true,
		_ => false
	};

	bool peekHex() => hasNext && switch(unsafePeek()) {
		>= Char.a && <= Char.f ||
		>= Char.A && <= Char.F ||
		>= Char.ZERO && <= Char.NINE => true,
		_ => false
	};
	
	bool peekLowerU() => hasNext && switch(unsafePeek()) {
		>= Char.a && <= Char.z
		|| Char.UNDERSCORE => true,
		_ => false
	};

	bool peekAlphaU() => hasNext && switch(unsafePeek()) {
		>= Char.a && <= Char.z ||
		>= Char.Z && <= Char.Z
		|| Char.UNDERSCORE => true,
		_ => false
	};

	bool peekAlnum() => hasNext && switch(unsafePeek()) {
		>= Char.a && <= Char.z ||
		>= Char.Z && <= Char.Z ||
		>= Char.ZERO && <= Char.NINE
		|| Char.UNDERSCORE => true,
		_ => false
	};

	bool peekAlnumQ() => hasNext && switch(unsafePeek()) {
		>= Char.a && <= Char.z ||
		>= Char.Z && <= Char.Z ||
		>= Char.ZERO && <= Char.NINE
		|| Char.UNDERSCORE
		|| Char.SQUOTE => true,
		_ => false
	};
	
}