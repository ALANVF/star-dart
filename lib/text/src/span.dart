import 'pos.dart';
import 'source_file.dart';

class Span {
	SourceFile? source;
	final Pos start;
	final Pos end;

	Span(this.start, this.end, this.source);
	Span.empty(this.source): start = Pos(0, 0), end = Pos(0, 0);
	Span.at(Pos pos, this.source): start = pos, end = pos.advance();
	Span.length(this.start, int length, this.source): end = start.advance(length);
	Span.range(Span from, Span to): start = from.start, end = to.end {
		if(from.source != to.source) {
			throw "The two spans originate from different sources!";
		} else {
			source = from.source;
		}
	}

	bool contains(Pos pos) => start <= pos && pos < end;

	bool intersects(Span other) => !(start >= other.end || other.start >= end);

	Span union(Span other) => Span.range(this, other);

	String prettyPrint() {
		return "${source?.path ?? "(Unknown)"}:${start.line + 1}:${start.column}";
	}

	//@override String toString() {}
}