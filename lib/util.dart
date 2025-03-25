// ignore_for_file: non_constant_identifier_names, constant_identifier_names

extension type const Char(int char) implements int {
	static const
		TAB = Char(9),
		LF = Char(10),
		CR = Char(13),
		SPACE = Char(32),
		BANG = Char(33),
		DQUOTE = Char(34),
		HASH = Char(35),
		DOLLAR = Char(36),
		PERCENT = Char(37),
		AND = Char(38),
		SQUOTE = Char(39),
		LPAREN = Char(40),
		RPAREN = Char(41),
		STAR = Char(42),
		PLUS = Char(43),
		COMMA = Char(44),
		MINUS = Char(45),
		DOT = Char(46),
		FSLASH = Char(47),
		ZERO = Char(48),
		ONE = Char(49),
		TWO = Char(50),
		THREE = Char(51),
		FOUR = Char(52),
		FIVE = Char(53),
		SIX = Char(54),
		SEVEN = Char(55),
		EIGHT = Char(56),
		NINE = Char(57),
		COLON = Char(58),
		SEMICOLON = Char(59),
		LT = Char(60),
		EQ = Char(61),
		GT = Char(62),
		QUESTION = Char(63),
		AT = Char(64),
		A = Char(65),
		B = Char(66),
		C = Char(67),
		D = Char(68),
		E = Char(69),
		F = Char(70),
		G = Char(71),
		H = Char(72),
		I = Char(73),
		J = Char(74),
		K = Char(75),
		L = Char(76),
		M = Char(77),
		N = Char(78),
		O = Char(79),
		P = Char(80),
		Q = Char(81),
		R = Char(82),
		S = Char(83),
		T = Char(84),
		U = Char(85),
		V = Char(86),
		W = Char(87),
		X = Char(88),
		Y = Char(89),
		Z = Char(90),
		LBRACK = Char(91),
		BSLASH = Char(92),
		RBRACK = Char(93),
		CARET = Char(94),
		UNDERSCORE = Char(95),
		BACKTICK = Char(96),
		a = Char(97),
		b = Char(98),
		c = Char(99),
		d = Char(100),
		e = Char(101),
		f = Char(102),
		g = Char(103),
		h = Char(104),
		i = Char(105),
		j = Char(106),
		k = Char(107),
		l = Char(108),
		m = Char(109),
		n = Char(110),
		o = Char(111),
		p = Char(112),
		q = Char(113),
		r = Char(114),
		s = Char(115),
		t = Char(116),
		u = Char(117),
		v = Char(118),
		w = Char(119),
		x = Char(120),
		y = Char(121),
		z = Char(122),
		LBRACE = Char(123),
		PIPE = Char(124),
		RBRACE = Char(125),
		TILDE = Char(126)
	;
	static final chars = {
		for(final i in 32.to(126)) String.fromCharCode(i): Char(i)
	};

	bool isAsciiPrintable() => 32 <= char && char <= 126;

	bool isAsciiControl() => (0 <= char && char < 32) || char == 127;
}

extension IntUtil on int {
	Char get char => Char(this);

	Iterable<int> to(int stop) sync* {
		for(var i = this; i <= stop; i++) {
			yield i;
		}
	}

	Iterable<int> upto(int stop) sync* {
		for(var i = this; i < stop; i++) {
			yield i;
		}
	}

	Iterable<int> times() sync* {
		for(var i = 0; i < this; i++) {
			yield i;
		}
	}
}

extension StringUtil on String {
	Char charAt(int index) => codeUnitAt(index).char;

	List<Char> get chars => codeUnits as List<Char>;
}

extension ListUtil<T> on List<T> {
	void addTimes(int times, T value) {
		/*final oldLen = this.length;
		this.length += times;
		for(final i in 0.upto(times)) {
			this[oldLen + i] = value;
		}*/
		this.addAll(List.filled(times, value));
	}

	Map<U, List<T>> groupBy<U>(U Function(T) fn, [bool Function(U, U)? equal]) {
		final found = <U, List<T>>{};

		if(equal == null) {
			for(final elem in this) {
				final value = fn(elem);
				
				found.putIfAbsent(value, () => []);
				found[value]!.add(elem);
			}
		} else {
			for(final elem in this) {
				final value = fn(elem);

				if(found.keys.where((k) => equal(k, value)).firstOrNull case final k?) {
					found[k]!.add(elem);
				} else {
					found[value] = [elem];
				}
			}
		}

		return found;
	}

	List<T> sorted([int Function(T, T)? compare]) => [...this]..sort(compare);
}

extension SetUtil<T> on Set<T> {
	bool operator [](T value) => contains(value);
	void operator []=(T value, bool state) {
		state? add(value) : remove(value);
	}
}