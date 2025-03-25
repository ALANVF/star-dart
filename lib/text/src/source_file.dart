import 'dart:core';
import 'dart:io';

import 'package:star/util.dart';
import 'cursor.dart';

class SourceFile implements Comparable<SourceFile> {
	late final File file;
	late final String text;
	final _lineStarts = <int>[];
	
	SourceFile(String path) {
		file = File(Uri.file(path).toFilePath());
		text = file.readAsStringSync().replaceAll("\r", "");
		_calculateLineStarts();
	}


	@override int compareTo(SourceFile other) => file.path == other.file.path ? 0 : -1;

	Iterator<Char> get iterator => text.chars.iterator;
	bool get isReal => file.existsSync();
	int get lineCount => _lineStarts.length;
	String get path => file.path;

	int _lineIndexToTextIndex(int index) {
		return index >= _lineStarts.length ? text.length : _lineStarts[index];
	}

	String line(int index) {
		final start = _lineIndexToTextIndex(index);
		final end = _lineIndexToTextIndex(index + 1);
		return text.substring(start, end + 1);
	}

	void _calculateLineStarts() {
		final cursor = Cursor();
		var lastLine = 0;

		_lineStarts.add(0);

		for(final (i, char) in text.chars.indexed) {
			cursor.appendChar(char);

			if(cursor.column == 0) {
				if(cursor.line != lastLine) {
					_lineStarts.add(i + 1);
					lastLine = cursor.line;
				} else {
					_lineStarts.last = i + 1;
				}
			}
		}
	}

	@override String toString() => file.path;
}