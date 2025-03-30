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
		
	}

	type T
	kind Options[T] is flags {

	}
}