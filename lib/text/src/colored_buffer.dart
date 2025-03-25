import 'dart:io';
import 'package:star/util.dart';
import 'package:star/text/text.dart';

typedef _Color = ({AnsiColor? fg, AnsiColor? bg});
typedef _Line = ({List<Char> text, List<_Color> color});

class ColoredBuffer {
	AnsiColor? fg = null;
	AnsiColor? bg = null;
	var cursor = (x: 0, y: 0);
	final lines = <_Line>[];

	void clear() {
		cursor = (x: 0, y: 0);
		resetColor();
		lines.clear();
	}

	void resetColor() {
		fg = bg = null;
	}

	void plot(int x, int y, Char ch) {
		_ensureBuffer(x, y);

		final line = lines[y];

		line.text[x] = ch;
		line.color[x] = (fg: fg, bg: bg);

		cursor = (x: x + 1, y: y);
	}

	void writeAt(int left, int top, String str) {
		_ensureBuffer(left + str.length, top);

		final line = lines[top];

		for(final i in 0.upto(str.length)) {
			final c = str.charAt(i);
			if(c == -1) throw "????????";
			line.text[left + i] = c;
			line.color[left + i] = (fg: fg, bg: bg);
		}

		cursor = (x: left + str.length, y: top);
	}

	void writeChar(Char ch) => plot(cursor.x, cursor.y, ch);
	void write(String str) => writeAt(cursor.x, cursor.y, str);

	void newline() {
		cursor = (x: 0, y: cursor.y + 1);
	}

	void writeln(String str) {
		writeAt(cursor.x, cursor.y, str);
		newline();
	}

	void fill(int left, int top, int width, int height, Char ch) {
		for(final j in 0.upto(height)) {
			final yp = top + j;

			_ensureBuffer(left + width - 1, yp);

			final line = lines[yp];

			for(final i in 0.upto(width)) {
				final xp = left + i;

				if(line.text.length < xp) {
					for(final _ in 0.to(left+1)) line.color.add((fg: fg, bg: bg));
					line.text.addTimes(left, Char.SPACE);
					line.text.add(ch);
					line.text.addTimes(xp - line.text.length, Char.SPACE);
					while(line.text.last == Char.SPACE) line.text.removeLast();
				} else {
					line.text[xp] = ch;
					line.color[xp] = (fg: fg, bg: bg);
				}
			}
		}

		cursor = (x: left + width, y: top + height - 1);
	}

	void recolorArea(int left, int top, int width, int height) {
		for(final j in 0.upto(height)) {
			final yp = top + j;

			_ensureBuffer(left + width - 1, yp);
			
			final line = lines[yp];
			
			for(final i in 0.upto(width)) {
				final xp = left + i;
				
				line.color[xp] = (fg: fg, bg: bg);
			}
		}
	}

	void outputTo(IOSink writer) {
		const reset = "\x1b[0m";

		writer.write(reset);

		for(final (:text, :color) in lines) {
			final lineLen = text.length;

			for(var i = 0; i < lineLen;) {
				final c = color[i];
				if(c.fg != null) {
					writer.write("\x1b[3${c.fg!.index}m");
				} else {
					writer.write("\x1b[39m$reset");
				}

				final start = i++;

				while(i < lineLen && color[start] == color[i]) i++;

				writer.add(text.sublist(start, i));
			}

			writer.writeln(reset);
		}

		writer.writeln(reset);

		//var block = [false];
		/*writer.flush().timeout(Duration(seconds: 1), onTimeout: () {
		//	block[0] = true;
			print("timed out");
		});*/
		//while(block[0] == false) {}
	}

	void recolor(int x, int y) {
		_ensureBuffer(x, y);
		lines[y].color[x] = (fg: fg, bg: bg);
	}

	void _ensureBuffer(int x, int y) {
		//if(y > lines.length) lines.length = y + 1;
		while(lines.length <= y) lines.add((text: [], color: []));

		final line = lines[y];
		final requiredChars = (x - line.text.length) + 1;

		if(requiredChars > 0) {
			final oldTextLen = line.text.length;
			final oldColorLen = line.color.length;
			//line.text.length += requiredChars;
			//line.color.length += requiredChars;
			line.text.addTimes(requiredChars, Char(0));
			line.color.addTimes(requiredChars, (fg: null, bg: null));
			for(final i in 0.upto(requiredChars)) {
				line.text[oldTextLen + i] = Char.SPACE;
				line.color[oldColorLen + i] = (fg: fg, bg: bg);
			}
		}
	}
}