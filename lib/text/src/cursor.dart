import 'package:star/util.dart';
import 'pos.dart';

class Cursor {
	int line = 0;
	int column = 0;
	bool lastCR = false;

	Cursor();

	Pos get pos => Pos(line, column);

	void append(String str) {
		for(final char in str.chars) {
			appendChar(char);
		}
	}

	void appendChar(Char char) {
		if(char == Char.CR) {
			line++;
			column = 0;
			lastCR = true;
		} else if(char == Char.LF) {
			if(lastCR) {
				lastCR = false;
			} else {
				line++;
				column = 0;
			}
		} else {
			if(char.isAsciiPrintable() || char == Char.TAB) {
				column++;
			}

			lastCR = false;
		}
	}
}