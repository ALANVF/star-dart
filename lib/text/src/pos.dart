//import 'package:meta/meta.dart';

extension type Pos._(int i) {
	Pos(int line, int column): i = (line << 16) | column;

	int get line => i >> 16;
	int get column => i & 0xffff;
	int get value => i;

	int compareTo(Pos p) => i - p.i;
	bool operator <(Pos p) => i < p.i;
	bool operator <=(Pos p) => i <= p.i;
	bool operator >(Pos p) => i > p.i;
	bool operator >=(Pos p) => i >= p.i;

	Pos advance([int amount = 1]) => Pos._(i + amount);
	Pos newline() => Pos._(i + 0x00010000);

	//@redeclare String toString() => "($line, $column)";
}