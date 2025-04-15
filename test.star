;[module Main is main {
	on [main] is main {
		my res = 0
		recurse my i = 0 {
			if i ?= 5 {
				res = i
				break
			} else {
				next with: i + 1
			}
		}
		1e
		Core[say: res]
	}
}]

use Abc[A, B].Def from: Foo[T]

module A of B, C.D is friend Foo is sealed is native `abc` {
	protocol Bar {

	}

	class Banana of Bar, Def is hidden {
		my a (Int)
		my b (Str) is getter `banana`

		on [abc] (Void)
		on [a: (Int) b: (Str)] is unordered

		init [new]

		operator `+` [other (Banana)] (Banana)
		operator `!` (Bool)
	}

	type T of A if T != Void && (A? || !B)
	kind Options[T] is flags {
		has abc
		has def
		has [foo]
		has [bar: a (Int)] {
			do label: `a` {
				break `a`
			}
			break
			next `a`
		}
	}

	alias A = Int
	alias B is hidden 
	alias C (Str) is noinherit {
		alias T
	}

	category A for B is hidden {

	}

	category C {

	}
}