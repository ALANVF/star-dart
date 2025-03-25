import 'dart:io';
import 'dart:math';
import 'package:star/reporting/src/diagnostic.dart';
import 'package:star/text/text.dart';
import 'package:star/util.dart';
import 'info.dart';

sealed class _Line {}
final class _Source extends _Line {
	final SourceFile source;
	final int line;
	_Source(this.source, this.line);
}
final class _Dot extends _Line {}
final class _Annotation extends _Line {
	final int line;
	final List<Info> annotations;
	_Annotation(this.line, this.annotations);
}

class LineCursor {
	int column = 0;
	int tabSize;

	LineCursor([this.tabSize = 4]);

	({bool isTab, int advance}) append(Char char) {
		final isTab = char == Char.TAB;
		final advance = isTab
			? tabSize - column % tabSize
			: !char.isAsciiControl() ? 1 : 0;

		column += advance;

		return (isTab: isTab, advance: advance);
	}
}

class DiagnosticRenderer {
	static const
		_angle_bar  = "|-", // "┌─",
		_line_bar   = "|", // "│",
		_caret      = "+", // "⌃",
		_up_arrow   = "^", // "↑",
		_line_curve = "\\"; // "╰";
	
	final IOSink writer;
	var surroundingLines = 1;
	var connectUpLines = 1;
	var tabSize = 4;
	var buffer = ColoredBuffer();

	DiagnosticRenderer([IOSink? writer]): writer = writer ?? stderr;

	void render(Diagnostic diag) {
		buffer = ColoredBuffer();

		renderDiagnosticHead(diag);

		final allInfos = diag.info
			.sorted((l, r) => l.span.start.compareTo(r.span.start))
			.groupBy((i) => i.span.source!, (l, r) => l.file == r.file);
		
		for(final infos in allInfos.values) renderInfoGroup(infos);

		buffer.outputTo(writer);
		writer.write("\x1b[0m");
	}

	void renderDiagnosticHead(Diagnostic diag) {
		buffer.fg = diag.severity.color;
		buffer.write(diag.severity.description);

		if(diag.code case final c?) buffer.write('[$c]');

		buffer.resetColor();

		if(diag.message case final m?) {
			buffer
			..write(": ")
			..write(m);
		}

		buffer.newline();
	}

	void renderInfoGroup(List<Info> infos) {
		final sourceFile = infos[0].span.source!;
		final linePrimitives = collectLinesToRender(infos);
		final maxLineIndex = [for(final l in linePrimitives) if(l is _Source) l.line].reduce(max);
		final lineNumberPadding = " " * (maxLineIndex + 1).toString().length;

		buffer.write('$lineNumberPadding $_angle_bar ${sourceFile.path}');
		
		if(infos.where((i) => i.priority == Priority.primary).firstOrNull case final info?) {
			buffer.write(':${info.span.start.line + 1}:${info.span.start.column}');
		}
		
		buffer.newline();
		buffer.writeln('$lineNumberPadding $_line_bar');
		
		for(final line in linePrimitives) {
			switch(line) {
				case _Source(:final source, :final line):
					buffer.write('${(line + 1).toString().padLeft(lineNumberPadding.length)} $_line_bar');
					renderSourceLine(source, line);
					buffer.newline();

				case _Annotation(:final line, :final annotations):
					renderAnnotationLines(line, annotations, '$lineNumberPadding $_line_bar');

				case _Dot():
					buffer.writeln('$lineNumberPadding $_line_bar...');
			}
		}
		
		buffer.writeln('$lineNumberPadding $_line_bar');
	}

	void renderSourceLine(SourceFile source, int line) {
		//final xOffset = buffer.cursor.x;

		buffer.fg = AnsiColor.white;

		final sourceLine = source.line(line);
		final lineCur = LineCursor(tabSize);

		for(final ch in sourceLine.chars) {
			if(ch == Char.CR || ch == Char.LF) break;
			if(lineCur.append(ch) case (:var advance, isTab: true)) {
				buffer.cursor = (x: buffer.cursor.x + advance, y: buffer.cursor.y);
			} else {
				buffer.writeChar(ch);
			}
		}

		// ...
	}

	void renderAnnotationLines(int lineN, List<Info> annotations, String prefix) {
		final sourceFile = annotations[0].span.source!;
		final line = sourceFile.line(lineN).trimRight();
		final annotationsOrdered = annotations.sorted((l, r) => l.span.start.compareTo(r.span.start));
		final arrowHeadColumns = <(int column, Info info)>[];
		
		buffer.write(prefix);
		
		final cursor = LineCursor(tabSize);
		var charIdx = 0;

		for(final annot in annotationsOrdered) {
			while(charIdx < annot.span.start.column) {
				if(charIdx < line.length) {
					buffer.cursor = (x: buffer.cursor.x + cursor.append(line.charAt(charIdx)).advance, y: buffer.cursor.y);
				} else {
					buffer.cursor = (x: buffer.cursor.x + 1, y: buffer.cursor.y);
				}

				charIdx++;
			}
			
			final arrowHead = annot.priority == Priority.normal? '-' : _caret;
			final startColumn = buffer.cursor.x;
			
			arrowHeadColumns.add((startColumn, annot));
			
			if(annot.priority == Priority.primary) buffer.fg = AnsiColor.red;
			else if(annot.priority == Priority.secondary) buffer.fg = AnsiColor.yellow;
			
			if(annot.priority != Priority.normal && annot.message != null) {
				buffer.write(_up_arrow);
				charIdx++;
			}

			while(charIdx < annot.span.end.column) {
				buffer.write(
					charIdx < line.length
						? arrowHead * cursor.append(line.charAt(charIdx)).advance
						: arrowHead
				);

				charIdx++;
			}

			if(annot.priority != Priority.normal) {
				// recolor line
				buffer.recolorArea(startColumn, buffer.cursor.y - 1, buffer.cursor.x - startColumn, 1);
				buffer.resetColor();
			}
		}
		
		buffer.newline();
		
		// From now on all previous ones will be one longer than the ones later
		var arrowBaseLine = buffer.cursor.y;
		var arrowBodyLength = 0;

		// We only consider annotations with messages
		for(final (i, (col, annot)) in arrowHeadColumns.reversed.where((a) => a.$2.message != null).indexed) {
			if(annot.priority == Priority.primary) buffer.fg = AnsiColor.red;
			else if(annot.priority == Priority.secondary) buffer.fg = AnsiColor.yellow;

			// Draw the arrow
			buffer.fill(col, arrowBaseLine, 1, arrowBodyLength + i, _line_bar.chars[0]);
			buffer.plot(col, arrowBaseLine + arrowBodyLength + i, _line_curve.chars[0]);
			arrowBodyLength++;
			arrowBodyLength += i;
			
			// Append the message
			if(annot.message!.contains("\n")) {
				final msgLines = annot.message!.split("\n");
				final oldX = buffer.cursor.x;
				buffer.write(' ${msgLines.removeAt(0)}');
				for(final msgLine in msgLines) {
					buffer.cursor = (x: oldX, y: buffer.cursor.y + 1);
					arrowBaseLine++;
					buffer.write(' $msgLine');
				}
			} else {
				buffer.write(' ${annot.message}');

			}
			if(annot.priority != Priority.normal) buffer.resetColor();
		}
		
		// Fill the in between lines with the prefix
		for(final i in 0.upto(arrowBodyLength)) {
			buffer.writeAt(0, arrowBaseLine + i, prefix);
		}

		// Reset cursor position
		buffer.cursor = (x: 0, y: arrowBaseLine + arrowBodyLength);
	}

	// Collects all the line subgroups
	List<_Line> collectLinesToRender(List<Info> infos) {
		final result = <_Line>[];
		
		// We need to group the spanned informations per line
		final groupedInfos = infos.groupBy((si) => si.span.start.line).entries.toList().sorted((a, b) => a.key - b.key);
		final sourceFile = infos[0].span.source!;

		// Now we collect each line primitive
		int? lastLineIndex = null;

		for(final j in 0.upto(groupedInfos.length)) {
			final infoGroup = groupedInfos[j];
			// First we determine the range we need to print for this info
			final currentLineIndex = infoGroup.key;
			final minLineIndex = max(lastLineIndex ?? 0, currentLineIndex - surroundingLines);
			var maxLineIndex = min(sourceFile.lineCount, currentLineIndex + surroundingLines + 1);
			
			if(j < groupedInfos.length - 1) {
				// There's a chance we step over to the next annotation
				final nextGroupLineIndex = groupedInfos[j + 1].key;
				maxLineIndex = min(maxLineIndex, nextGroupLineIndex);
			}
			
			// Determine if we need dotting or a line in between
			if(lastLineIndex != null) {
				final difference = minLineIndex - lastLineIndex;
				if(difference <= connectUpLines) {
					// Difference is negligible, connect them up, no reason to dot it out
					for(final i in 0.upto(difference)) {
						result.add(_Source(sourceFile, lastLineIndex + i));
					}
				} else {
					// Bigger difference, dot out
					result.add(_Dot());
				}
			}
			lastLineIndex = maxLineIndex;
			
			// Now we need to print all the relevant lines
			for(final i in minLineIndex.upto(maxLineIndex)) {
				result.add(_Source(sourceFile, i));
				
				// If this was an annotated line, yield the annotation
				if(i == infoGroup.key) result.add(_Annotation(i, infoGroup.value));
			}
		}
		
		return result;
	}
}