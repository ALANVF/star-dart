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

;[use Abc[A, B].Def from: Foo[T]

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
			a = 3 + 5 %% 2 ?= true || foo?
			a -> b = c -> [foo]
			a.b
			-> c = 1 + 2
			-> [foo: bar]
			--> x++
			a[b]
			a[b: c]
			a[b: c d: e]
			A[B]
			A[B c]
			a[B]
			a[B c]
			1 + 2 * 3
			(1 + 2) * 3
			return !1.foo?
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
}]

;[alias TypeVarCtx (Dict[TypeVar, Type])

kind Ctx {
	;-- A type decl
	has [decl: (TypeDecl)] {
		thisType = decl.thisType
	}

	;-- A category
	has [category: (Category)] {
		thisType = category.thisType
	}
	
	;-- An empty method
	has [emptyMethod: (EmptyMethod)]

	;-- A callable method
	has [method: (RealMethod)]

	;-- A member of a type
	has [member: (Member)]

	;-- A tagged case
	has [taggedCase: (TaggedCase)]

	;-- Code of some kind
	has [code]

	;-- A pattern (TODO: should this track the target type?)
	has [pattern]

	;-- A `recurse` statement
	has [recurse: lvars (Array[Tuple[String, Local]])]

	;-- Code in an instance cascade
	has [objCascade: (Maybe[Type])]

	;-- Code in a static (type) cascade
	has [typeCascade]

	;-- Context for typevars when doing type checking/inference
	has [typevars: (TypeVarCtx)]


	my outer (Maybe[Ctx]) = Maybe[none]
	my thisType (Type)
	my locals (Dict[Str, Local]) = #()
	my labels (Dict[Str, Stmt]) = #()


	on [typeDecl] (AnyTypeDecl) is getter {
		match this {
			at This[decl: my decl] => return decl
			at This[category: my cat] => return cat
			at This[emptyMethod: my mth] => return mth.decl
			at This[method: my mth] => return mth.decl
			at This[member: my mem] => return mem.decl
			at This[taggedCase: my tcase] => return tcase.decl
			else {
				match outer at Maybe[the: my outer'] {
					return outer'.typeDecl
				} else {
					throw "impossible!"
				}
			}
		}
	}

	on [typeLookup] (TypeLookupDecl) is getter {
		match this {
			at This[decl: my decl] => return decl
			at This[category: my cat] => return cat
			at This[emptyMethod: my mth] => return mth.decl
			at This[method: my mth] => return mth
			at This[member: my mem] => return mem.decl
			at This[taggedCase: my tcase] => return tcase.decl
			else {
				match outer at Maybe[the: my outer'] {
					return outer'.typeLookup
				} else {
					throw "impossible!"
				}
			}
		}
	}


	on [innerDecl: decl (TypeDecl)] (This) {
		return This[
			outer: Maybe[the: this]
			:decl
		]
	}

	on [innerCategory: cat (Category)] (This) {
		return This[
			outer: Maybe[the: this]
			category: cat
		]
	}

	on [innerEmptyMethod: method (EmptyMethod)] (This) {
		return This[
			outer: Maybe[the: this]
			:thisType
			emptyMethod: method
		]
	}

	on [innerMethod: method (RealMethod)] (This) {
		return This[
			outer: Maybe[the: this]
			:thisType
			:method
		]
	}

	on [innerMember: member (Member)] (This) {
		return This[
			outer: Maybe[the: this]
			:thisType
			:member
		]
	}

	on [innerTaggedCase: taggedCase (TaggedCase)] (This) {
		return This[
			outer: Maybe[the: this]
			:thisType
			:taggedCase
		]
	}

	on [innerCode] (This) {
		return This[code]
		-> outer = Maybe[the: this]
		-> thisType = thisType
	}

	on [innerPattern] (This) {
		return This[pattern]
		-> outer = Maybe[the: this]
		-> thisType = thisType
	}

	on [innerRecurse: lvars (Array[Tuple[String, Local]])] (This) {
		return This[recurse: lvars]
		-> outer = Maybe[the: this]
		-> thisType = thisType
	}

	on [innerObjCascade: type (Maybe[Type])] (This) {
		return This[
			outer: Maybe[the: this]
			thisType: type[orElse: thisType] ;@@ TODO: fix
			objCascade: type
		]
	}

	on [innerTypeCascade: type (Type)] (This) {
		return This[typeCascade]
		-> outer = Maybe[the: this]
		-> thisType = type
	}

	on [innerTypevars: typevars (TypeVarCtx)] (This) {
		return This[
			outer: Maybe[the: this]
			:thisType
			:typevars
		]
	}


	;== Errors

	on [addError: error (Error)] {
		match this at (
			|| Ctx[decl: my source (HasErrors)]
			|| Ctx[category: my source (HasErrors)]
			|| Ctx[emptyMethod: my source (HasErrors)]
			|| Ctx[method: my source (HasErrors)]
			|| Ctx[member: my source (HasErrors)]
			|| Ctx[taggedCase: my source (HasErrors)]
		) {
			source.errors[add: error]
		} else {
			match outer at Maybe[the: my outer'] {
				outer'[addError: error]
			} else {
				throw "Cannot add error to unknown context source!"
			}
		}
	}


	;== Label lookup

	on [findLabel: label (Str)] (Maybe[Stmt]) {
		match labels[maybeAt: label] at Maybe[the: my res] {
			return Maybe[the: res]
		} else {
			match outer at Maybe[the: my outer'] {
				return outer'[findLabel: label]
			} else {
				return Maybe[none]
			}
		}
	}


	;== Variable lookup

	on [findLocal: name (Str) depth: (Int) = 0] (Maybe[Local]) {
		match locals[maybeAt: name] at Maybe[the: my local] if depth ?= 0 || (depth--, false) {
			return Maybe[the: local]
		} else {
			match outer at Maybe[the: my outer'] {
				match this {
					at This[objCascade: Maybe[the: my objType]] {
						match objType[
							in: this
							findInstance: name
							from: outer'.typeDecl.thisType
							isGetter: true
						] at SingleInst[member: my member] if depth ?= 0 || (depth--, false) {
							return Maybe[the: Local.Field[ctx: this :member]]
						} else {
							return outer'[findLocal: name :depth]
						}
					}

					at This[typeCascade] => throw "todo"

					at This[pattern] => return outer'[findLocal: name :depth] ;@@ TODO

					at (
						|| This[emptyMethod: AnyMethod[decl: my decl]]
						|| This[method: AnyMethod[decl: my decl]]
						|| This[member: Member[decl: my decl]]
						|| This[taggedCase: TaggedCase[decl: my decl]]
					) {
						my isStatic = !this[allowsThis]

						my allMembers = decl[instanceMembers: decl]
						-> [InPlace keepIf: {|member (Member)|
							return member.name ?= name && (
								|| !isStatic
								|| member.isStatic
								|| {
									match member.decl at (Module) {
										return true
									} else {
										return false
									}
								}
							)
						}]
						-> [InPlace unique]

						match allMembers[Type mostSpecific: Member$0.type.value] {
							at #[] => return Maybe[none]
							at #[my member] => return Maybe[the: locals[at: name] = Local.Field[ctx: this :member]]
							at my members => throw "todo"
						}
					}

					else => return outer'[findLocal: name :depth]
				}
			} else {
				return Maybe[none]
			}
		}
	}

	on [allowsThis] (Bool) {
		match this {
			at This[decl: (Module)] => return false
			at This[decl: _] => return true

			at This[category: _] => return true ; meh

			at This[emptyMethod: (StaticInit) || (StaticDeinit)] => return false
			
			at This[method: (StaticMethod)] => return false

			at This[member: my mem] => return !mem.isStatic && {
				match outer at Maybe[the: my outer'] {
					return outer'[allowsThis]
				} else {
					return true
				}
			}

			at This[taggedCase: _] => return true

			at This[objCascade: _] => return true

			else => match outer at Maybe[the: my outer'] {
				return outer'[allowsThis]
			} else {
				return true
			}
		}
	}

	on [canAssignReadonlyField] (Bool) {
		match this {
			at This[emptyMethod: (DefaultInit) || (StaticDeinit)] => return true
			
			at This[method: (Init)] => return true

			at This[taggedCase: _] => return true

			at This[code] || This[pattern] || This[typevars: _] {
				match outer at Maybe[the: my outer'] {
					return outer'[canAssignReadonlyField]
				} else {
					return false
				}
			}

			else => return false
		}
	}

	on [tryGetRecurse] (Maybe[Array[Tuple[String, Local]]]) {
		match this {
			at This[recurse: my lvars] => return Maybe[the: lvars]
			at (
				|| This[block] || This[blockExpr]
				|| This[pattern]
				|| This[objCascade: _] || This[typeCascade]
			) => match outer at Maybe[the: my outer'] {
				return outer[tryGetRecurse]
			} else {
				return Maybe[none]
			}
			else => return Maybe[none]
		}
	}


	;== Type lookup

	on [findType: path (TypePath)] (Maybe[Type]) {
		my found (Maybe[Type]), match this {
			at This[objCascade: Maybe[the: my objType]] {
				#{my depth, my path'} = path[toLookupPath: this.typeLookup]
				match objType[
					findType: path'
					search: Search.start
					from: Maybe[the: this.typeDecl]
					:depth
				] at Maybe[the: found = _] {} else {
					return outer.value[findType: path]
				}
			}

			at This[decl: _] <= _ <= This[method: _] {
				#{my depth, my path'} = path[toLookupPath: this.typeLookup]
				found = this.typeLookup[
					findType: path'
					search: Search.start
					from: Maybe[the: this.typeDecl]
					:depth
				]
			}

			else => return outer.value[findType: path]
		}

		match found at Maybe[the: my type] {
			match type at Type[type: my type' args: my args] {
				my typeDecl = this.typeDecl
				my typeLookup = this.typeLookup
				
				return Maybe[the: Type[
					type: type'
					args: args[collect: {|arg (Type)|
						match arg at Type[depth: my depth lookup: my lookup source: _] {
							match typeLookup[
								findType: lookup
								search: Search.start
								from: Maybe[the: typeDecl]
								:depth
							] at Maybe[the: my arg'] {
								return arg'
							} else {
								;[_.]this[addError: TypeError[invalidTypeLookup: arg.span.value]]
								return arg
							}
						} else {
							return arg
						}
					}]
					span: {
						if type.span? {
							return type.span
						} else {
							return type'.span
						}
					}
				]]
			} else {
				return Maybe[the: type]
			}
		} else {
			match outer at Maybe[the: my outer'] {
				return outer'[findType: path]
			} else {
				this[addError: TypeError[invalidTypeLookup: path.span]]
				return Maybe[none]
			}
		}
	}

	on [findTypevar: typevar (TypeVar)] (Maybe[Type]) {
		match this at This[typevars: my typevars] {
			return typevars[maybeAt: typevar]
		} else {
			match outer at Maybe[the: my outer'] {
				return outer'[findTypevar: typevar]
			} else {
				return Maybe[none]
			}
		}
	}

	on [findTypevarOf: typevar (TypeVar)] (Maybe[TypeVar]) {
		match this at This[typevars: my typevars] {
			for my tvar, my type in: typevars {
				match type at Maybe[the: Type[:typevar]] {
					return Maybe[the: tvar]
				}
			}

			return Maybe[none]
		} else {
			match outer at Maybe[the: my outer'] {
				return outer'[findTypevarOf: typevar]
			} else {
				return Maybe[none]
			}
		}
	}


	;== Describing

	on [description] (Str) is getter => return this[description: true]
	on [description: isTop (Bool)] (Str) is hidden {
		match this {
			at This[decl: my decl] => return "\(decl.declName) \(decl.fullName)"
			
			at This[category: _] => throw "todo"
			
			at This[emptyMethod: my mth] => return "\(mth.declName) for \(outer.value[description: false])"

			at This[method: my mth] {
				my sig = {
					match mth at (Operator) {
						return "`\(mth.methodName)`"
					} else {
						return "[\(mth.methodName)]"
					}
				}
				
				return "\(mth.declName) \(sig) for \(outer.value[description: false])"
			}

			at This[member: my mem] => return "member `\(mem.name)` for \(outer.value[description: false])"
			
			at This[taggedCase: my tcase] => return "tagged case [...] for \(outer.value[description: false])"

			at This[code] if isTop => return "{ ... } in \(outer.value[description: false])"

			at This[pattern] if isTop => return "pattern ... in \(outer.value[description: false])"

			at This[recurse: _] => return "recurse ... in \(outer.value[description: false])"

			at This[objCascade: _] => throw "todo"

			at This[typeCascade] => throw "todo"

			else => return outer.value[description: false]
		}
	}
}]


use #[WindowsInput, WindowsInput.Native] from: "WindowsInput"
use #(
	System => #(
		Windows => #[
			Controls
			Media
			Threading
			Input
		]
		_ => #[
			Diagnostics
			Threading.Tasks
		]
	)
) from: "DotNet" as: #(
	System.Windows => #(
		HorizontalAlignment => Horiz
		VerticalAlignment => Vertical
	)
)


module Main {
	;== Constants

	my fill_default is readonly = SolidColorBrush[new: Color[r: 223 g: 223 b: 223]]
	my fill_pressed is readonly = SolidColorBrush[new: Color[r: 123 g: 123 b: 223]]

	my opacity_default is readonly = 0.3
	my opacity_end is readonly = 1.0

	my input is readonly = InputSimulator[new]
	my keyboard is readonly = input.keyboard


	;== Keys

	my shiftKey (AnyKeyButton)
	my ctrlKey (AnyKeyButton)
	my altKey (AnyKeyButton)
	my keys (Array[KeyButton])


	;== Other globals

	my prevProc = Maybe[Process][none]
	
	my state = State[new]

	;-- immutable so it plays nice with multi-touch async
	my activeKeys = Immutable.Dict[Int, ActiveKey] #()
	

	;== Pressing keys

	on [getInputFocus] (Bool) {
		match prevProc {
			at Maybe[the: my proc] if proc.hasExited {
				prevProc = Maybe[none]
				return false
			}

			at Maybe[the: my proc] {
				Win32Api[setForegroundWindow: proc.mainWindowHandle]
				return true
			}

			at Maybe[none] => return false
		}
	}

	on [keyPress: code (KeyCode)] {
		if This[getInputFocus] {
			if state.shift !! state.ctrl !! state.alt {
				keyboard[keyPress: code]
			} else {
				keyboard[
					modifiers: #[] -> {
						if state.shift => this[add: KeyCode.shift]
						if state.ctrl => this[add: KeyCode.control]
						if state.alt => this[add: KeyCode.menu]
					}
					keyPress: code
				]
			}
		}
	}


	;== Other key stuff

	on [afterKey: button (StackPanel)] (Int) => return button.margin.left[Int] + button.panel.width[Int] + 10
	
	on [makeBasicKey: name (Str) x: (Int) y: (Int) width: (Int), textWidth (Int)] (StackPanel) {
		return StackPanel[new]
		-> width = width[Dec]
		-> height = 50.0
		-> margin = Thickness[left: x[Dec] top: y[Dec]]
		-> horizontalAlignment = Horiz.left
		-> verticalAlignment = Vertical.top
		-> orientation = Orientation.vertical
		-> background = fill_default
		-> children
		--> [add: Label[new]]
		---> content = name
		---> width = [textWidth+3 Dec]
		---> margin = Thickness[left: 0.0 top: 12.0]
		---> renderTransformOrigin = Point[x: 0.5 y: 0.5]
		---> horizontalAlignment = Horiz.center
		---> horizontalContentAlignment = Horiz.center
		---> zIndex = 5
		---> fontSize = 14.0
	}

	type Name if Name ?= Str || Name ?= Char
	on [
		makeKeyOf: name1 (Name), name2 (Name)
		x: (Int), x2 (Int)
		y: (Int)
		width: (Int), width1 (Int), width2 (Int)
	] (AnyKeyButton) {
		my panel = StackPanel[new]
		-> width = width[Dec]
		-> height = 50.0
		-> margin = Thickness[left: x[Dec] top: y[Dec]]
		-> horizontalAlignment = Horiz.left
		-> verticalAlignment = Vertical.top
		-> orientation = Orientation.vertical
		-> background = fill_default
		-> children
		--> [add: my label1 = Label[new]]
		---> content = name1
		---> width = [width1+3 Dec]
		---> margin = Thickness[left: 0.0 top: 12.0]
		---> renderTransformOrigin = Point[x: 0.5 y: 0.5]
		---> horizontalContentAlignment = Horiz.center
		---> zIndex = 5
		---> fontSize = 14.0
		--> [add: my label2 = Label[new]]
		---> content = name2
		---> width = [width2+3 Dec]
		---> height = 30.0
		---> margin = Thickness[left: x2[Dec] top: -55.0]
		---> renderTransformOrigin = Point[x: 0.5 y: 0.5]
		---> horizontalContentAlignment = Horiz.center
		---> verticalContentAlignment = Vertical.top
		---> zIndex = 5
		---> fontSize = 14.0

		return AnyKeyButton[:panel :label1 :label2]
	}

	on [makeKey: key (Key) x: (Int) y: (Int) width: (Int)] (KeyButton) {
		AnyKeyButton #{my panel, my label1, my label2} = This[
			makeKeyOf: key.primary, key.secondary
			:x, width - 20
			:y
			:width, 20, 25
		]

		return KeyButton[:panel :label1 :label2 :key]
	}

	on [x: (Int) y: (Int) makeRow: keys (Array[Key])] (Array[KeyButton]) {
		return keys[collect: {|key, i|
			return This[
				makeKey: key
				x: x + (i * 60)
				:y
				width: 50
			]
		}]
	}


	;== State

	on [resetState] {
		if state.shift {
			keyShift.background = fill_default
			state.shift = false
			for KeyButton #{_, my label, _, my key} in: keys {
				label.content = key.primary
			}
		}

		if state.ctrl {
			keyCtrl.background = fill_default
			state.ctrl = false
		}

		if state.alt {
			keyAlt.background = fill_default
			state.alt = false
		}
	}


	;== Timing/repeating

	on [timePressed: timer (DispatcherTimer) ms: (Dec) button: (StackPanel)] (Task[Bool]) {
		my task = TaskCompletionSource[Bool][new]

		timer.interval = TimeSpan[fromMilliseconds: ms]

		;-- maybe destructuring could be used for mutual recursion instead?
		my tick = Box[new: {|| }]
		my onUp = {||
			timer[stop]
			
			if task.task.status ?= TaskStatus.running {
				button
				-> previewTouchUp
				--> [remove: this]
				-> touchLeave
				--> [remove: this]

				timer.tick[remove: tick.value]

				task.result = false
			}
		}
		tick.value = {||
			button
			-> previewTouchUp
			--> [remove: onUp]
			-> touchLeave
			--> [remove: onUp]

			timer
			-> [stop]
			-> tick
			--> [remove: this]

			task.result = true
		}

		button
		-> previewTouchUp
		--> [add: onUp]
		-> touchLeave
		--> [add: onUp]

		timer
		-> tick
		--> [add: tick.value]
		-> [start]

		return task.task
	}

	on [maybeRepeat: button (StackPanel) key: (KeyCode)] {
		my timer = DispatcherTimer[new]

		This[timePressed: timer ms: 1000.0 :button][andThen: {|result (Bool)| (Maybe[Task[Void]])
			if result {
				This[keyPress: key]
				return Maybe[the: This[timePressed: timer ms: 20.0 :button][andThen: this]]
			} else {
				return Maybe[none]
			}
		}]
	}

	
	;== Events

	on [keyTouchDown: button (StackPanel) e: (TouchEventArgs) index: (Int)] {
		button.background = fill_pressed
		activeKeys = activeKeys[
			at: index
			add: ActiveKey[startTouch: e[touchPointFor: button]]
		]
	}

	on [keyTouchUp: button (StackPanel) index: (Int) key: (KeyCode)] {
		match activeKeys[maybeRemoveAt: index] at Maybe[the: #{_, activeKeys = _}] {
			button.background = fill_default
			This[keyPress: key]
		}
	}

	type B of AnyKeyButton
	on [keyTouchMove: button (B) e: (TouchEventArgs) index: (Int) left: (Int)] {
		match activeKeys[maybeFind: index] at Maybe[the: my activeKey] {
			my y = activeKey.touchPoint.position.y
			my y' = e[touchPointFor: button].position.y
			my diff = y' - y

			if diff > 3.0 {
				my n = (12.0 + (2.0 * diff[abs])) / 100.0

				button
				-> label1
				--> opacity = [1.0 - n min: opacity_default max: 1.0]
				-> label2
				--> opacity = [n min: 0.0 max: opacity_end]
				--> margin
				---> left = [0.0 max: left[Dec] - diff]
				--> [updateLayout]
			}

			if diff > 10.0 {
				activeKey.flicked ||= true
				button.label1
				-> margin
				--> top = 12.0 + (diff / 2.0)
				-> [updateLayout]
			}
		}
	}

	type B of AnyKeyButton
	type Name if Name ?= Str || Name ?= Char
	on [keyTouchLeave: button (B) index: (Int) left: (Int) name: name (Name) key: (KeyCode)] {
		match activeKeys[maybeRemoveAt: index] at Maybe[the: #{ActiveKey[flicked: true], activeKeys = _}] {
			state.shift = true

			button
			-> panel
			--> background = fill_default
			-> label1
			--> content = name
			--> opacity = opacity_end
			--> margin
			---> top = 12.0
			--> [updateLayout]
			-> label2
			--> opacity = opacity_default
			--> margin
			---> left = left[Dec]
			--> [updateLayout]

			This
			-> [keyPress: key]
			-> [resetState]
		}
	}
	

	;== Do things

	on [buildWindow: window (Window)] {
		;== Content

		my mainGrid = Grid[new]
		-> minWidth = window.width - 20
		-> minHeight = window.height - 20
		-> margin = Thickness[left: 10.0 top: 0.0]
		-> horizontalAlignment = Horiz.stretch
		-> verticalAlignment = Vertical.top

		my debugLabel = Label[new]
		-> content = "Label"
		-> width = 413.0
		-> height = 24.0
		-> margin = Thickness[left: 140.0 top: 10.0]
		-> horizontalAlignment = Horiz.left
		-> verticalAlignment = Vertical.top

		keyCtrl = This[makeBasicKey: "Ctrl" x: 10 y: 280 width: 45, 35]
		
		keyAlt = This[makeBasicKey: "Alt" x: This[afterKey: keyCtrl] y: 280 width: 45, 35]

		my keySpace = StackPanel[new]
		-> width = 300.0
		-> height = 50.0
		-> margin = Thickness[left: 0.0 top: 280.0]
		-> horizontalAlignment = Horiz.center
		-> verticalAlignment = Vertical.top
		-> background = fill_default

		keyShift = This[makeBasicKey: "Shift" x: 10 y: 220 width: 110, 35]

		my keyTab = This[
			makeKeyOf: "Tab", "Detab"
			x: 10, 20
			y: 100
			width: 65, 30, 50
		]

		keys = #[
			...This[x: This[afterKey: keyShift] y: 220 makeRow: #[
				Key[primary: #"z" secondary: #"Z" code: KeyCode.vk_z]
				Key[primary: #"x" secondary: #"X" code: KeyCode.vk_x]
				Key[primary: #"c" secondary: #"C" code: KeyCode.vk_c]
				Key[primary: #"v" secondary: #"V" code: KeyCode.vk_v]
				Key[primary: #"b" secondary: #"B" code: KeyCode.vk_b]
				Key[primary: #"n" secondary: #"N" code: KeyCode.vk_n]
				Key[primary: #"m" secondary: #"M" code: KeyCode.vk_m]
				Key[primary: #"," secondary: #"<" code: KeyCode.oem_comma]
				Key[primary: #"." secondary: #">" code: KeyCode.oem_period]
				Key[primary: #"/" secondary: #"?" code: KeyCode.oem_2]
			]]
			...This[x: 100 y: 160 makeRow: #[
				Key[primary: #"a" secondary: #"A" code: KeyCode.vk_a]
				Key[primary: #"s" secondary: #"S" code: KeyCode.vk_s]
				Key[primary: #"d" secondary: #"D" code: KeyCode.vk_d]
				Key[primary: #"f" secondary: #"F" code: KeyCode.vk_f]
				Key[primary: #"g" secondary: #"G" code: KeyCode.vk_g]
				Key[primary: #"h" secondary: #"H" code: KeyCode.vk_h]
				Key[primary: #"j" secondary: #"J" code: KeyCode.vk_j]
				Key[primary: #"k" secondary: #"K" code: KeyCode.vk_k]
				Key[primary: #"l" secondary: #"L" code: KeyCode.vk_l]
				Key[primary: #";" secondary: #":" code: KeyCode.oem_1]
				Key[primary: #"'" secondary: #"\"" code: KeyCode.oem_7]
			]]
			...This[x: This[afterKey: keyTab.panel] y: 100 makeRow: #[
				Key[primary: #"q" secondary: #"Q" code: KeyCode.vk_q]
				Key[primary: #"w" secondary: #"W" code: KeyCode.vk_w]
				Key[primary: #"e" secondary: #"E" code: KeyCode.vk_e]
				Key[primary: #"r" secondary: #"R" code: KeyCode.vk_r]
				Key[primary: #"t" secondary: #"T" code: KeyCode.vk_t]
				Key[primary: #"y" secondary: #"Y" code: KeyCode.vk_y]
				Key[primary: #"u" secondary: #"U" code: KeyCode.vk_u]
				Key[primary: #"i" secondary: #"I" code: KeyCode.vk_i]
				Key[primary: #"o" secondary: #"O" code: KeyCode.vk_o]
				Key[primary: #"p" secondary: #"P" code: KeyCode.vk_p]
				Key[primary: #"[" secondary: #"{" code: KeyCode.oem_4]
				Key[primary: #"]" secondary: #"}" code: KeyCode.oem_6]
				Key[primary: #"\\" secondary: #"|" code: KeyCode.oem_5]
			]]
			my keyBacktick = This[
				makeKey: Key[primary: #"`" secondary: #"~" code: KeyCode.oem_3]
				x: 10
				y: 40
				width: 30
			]
			...This[x: This[afterKey: keyBacktick.panel] y: 40 makeRow: #[
				Key[primary: #"1" secondary: #"!" code: KeyCode.vk_1]
				Key[primary: #"2" secondary: #"@" code: KeyCode.vk_2]
				Key[primary: #"3" secondary: #"#" code: KeyCode.vk_3]
				Key[primary: #"4" secondary: #"$" code: KeyCode.vk_4]
				Key[primary: #"5" secondary: #"%" code: KeyCode.vk_5]
				Key[primary: #"6" secondary: #"^" code: KeyCode.vk_6]
				Key[primary: #"7" secondary: #"&" code: KeyCode.vk_7]
				Key[primary: #"8" secondary: #"*" code: KeyCode.vk_8]
				Key[primary: #"9" secondary: #"(" code: KeyCode.vk_9]
				Key[primary: #"0" secondary: #")" code: KeyCode.vk_0]
				Key[primary: #"-" secondary: #"_" code: KeyCode.oem_minus]
				Key[primary: #"=" secondary: #"+" code: KeyCode.oem_plus]
			]]
		]

		my keyQuote = keys[find: $0.key.primary ?= #"'"]
		my keyEnter = This[makeBasicKey: "Enter" x: This[afterKey: keyQuote] y: 160 width: 95, 65]

		my keyBackspace = This[makeBasicKey: "Backspace" x: This[afterKey: keys[at: -1].panel] y: 40 width: 85, 70]


		;== Layout

		window.content = mainGrid
		-> children
		--> [add: debugLabel]
		--> [add: keyCtrl]
		--> [add: keyAlt]
		--> [add: keySpace]
		--> [add: keyShift]
		--> [add: keyEnter]
		--> [add: keyTab]
		--> [addAll: keys[collect: $0.panel]]
		--> [add: keyBackspace]

		keyTab.label2.opacity = opacity_default
		for my i, my button in: keys {
			button
			-> panel
			--> tag = i
			-> label2
			--> opacity = opacity_default
		}


		;== Events

		Stylus[isPressAndHoldEnabled: window] = false

		keyCtrl
		-> touchDown
		--> [add: {||
			if state.ctrl {
				state.ctrl = false
			} else {
				keyCtrl.background = fill_pressed
				state.ctrl = true
			}
		}]
		-> touchUp
		--> [add: {||
			if !state.ctrl {
				keyCtrl.background = fill_default
			}
		}]

		keyAlt
		-> touchDown
		--> [add: {||
			if state.alt {
				state.alt = false
			} else {
				keyAlt.background = fill_pressed
				state.alt = true
			}
		}]
		-> touchUp
		--> [add: {||
			if !state.alt {
				keyAlt.background = fill_default
			}
		}]

		keySpace
		-> touchDown
		--> [add: {|_1, e|
			This
			-> [keyTouchDown: keySpace :e index: -4]
			-> [maybeRepeat: keySpace key: KeyCode.space]
		}]
		-> touchUp
		--> [add: {||
			This
			-> [keyTouchUp: keySpace index: -4 key: KeyCode.space]
			-> [resetState]
		}]

		keyShift
		-> touchDown
		--> [add: {||
			if state.shift {
				state.shift = false
			} else {
				keyShift.background = fill_pressed
				state.shift = true
				;for KeyButton #{}
			}
		}]
		-> touchUp
		--> [add: {||
			if !state.shift {
				keyShift.background = fill_default
			}
		}]

		keyTab.panel
		-> touchDown
		--> [add: {|_1, e|
			This
			-> [keyTouchDown: keyTab.panel :e index: -1]
			-> [maybeRepeat: keyTab.panel key: KeyCode.tab]
		}]
		-> touchUp
		--> [add: {||
			This
			-> [keyTouchUp: keyTab.panel index: -1 key: KeyCode.tab]
			-> [resetState]
		}]
		-> touchMove
		--> [add: {|_1, e|
			This[keyTouchMove: keyTab :e index: -1 left: 20]
		}]
		-> touchLeave
		--> [add: {||
			state.shift = true
			This[keyTouchLeave: keyTab index: -1 left: 20 name: "Tab" key: KeyCode.tab]
			state.shift = false
			This[resetState]
		}]

		keyBackspace
		-> touchDown
		--> [add: {|_1, e|
			This
			-> [keyTouchDown: keyBackspace :e index: -3]
			-> [maybeRepeat: keyBackspace key: KeyCode.back]
		}]
		-> touchUp
		--> [add: {||
			This
			-> [keyTouchUp: keyBackspace index: -3 key: KeyCode.back]
			-> [resetState]
		}]

		for my button = KeyButton #{my panel, _, _, my key} in: keys {
			my index = panel.tag[Int]
			my left = [button ?= keyBacktick yes: 10 no: 30]

			panel
			-> touchDown
			--> [add: {|_1, e|
				This
				-> [keyTouchDown: panel :e :index]
				-> [maybeRepeat: panel key: key.code]
			}]
			-> touchUp
			--> [add: {||
				This
				-> [keyTouchUp: panel :index key: key.code]
				-> [resetState]
			}]
			-> touchMove
			--> [add: {|_1, e|
				This[keyTouchMove: button :e :index :left]
			}]
			-> touchLeave
			--> [add: {||
				This[keyTouchLeave: button :index :left name: key.primary key: key.code]
			}]
		}

		window
		-> touchUp
		--> [add: {||
			if !state.shift => keyShift.background = fill_default
			if !state.ctrl => keyCtrl.background = fill_default
			if !state.alt => keyAlt.background = fill_default
			keySpace.background = fill_default
			keyEnter.background = fill_default
			keyBackspace.background = fill_default
		}]
		-> touchLeave
		--> [add: {||
			for KeyButton[panel: my panel] in: keys {
				panel.background = fill_default
			}
		}]
		-> activated
		--> [add: {||
			my current = Win32Api[getForegroundWindow]
			my prev = Win32Api[getWindow: current, Win32Api.GetWindow.next]
			my proc = {
				my pid = Native.UInt32 0
				Win32Api[getWindowThreadProcessId: prev, pid[Native address][Native.Ptr[Native.UInt32]]]
				return Process[getProcessById: pid]
			}

			prevProc = Maybe[the: proc]
			window.topmost = true
		}]
		-> deactivated
		--> [add: {||
			if prevProc? {
				window.topmost = false
			} else {
				window.topmost = true
			}
		}]
		-> sizeChanged
		--> [add: {|_1, e|
			Size #{my w, my h} = e.previousSize
			Size #{my w', my h'} = e.newSize

			if (e.widthChanged || e.heightChanged) && (w? || h?) {
				my wc = [w? yes: w' / w no: 1.0]
				my hc = [h? yes: h' / h no: 1.0]

				for my child (FrameworkElement) in: mainGrid {
					#{my ww, my hh} = {
						match child.layoutTransform at ScaleTransform[scaleX: my x scaleY: my y] {
							return #{x, y}
						} else {
							return #{1.0, 1.0}
						}
					}

					child
					-> layoutTransform = ScaleTransform[
						scaleX: ww * [e.widthChanged && child.width[Native isNormal] yes: wc no: 1.0]
						scaleY: hh * [w.heightChanged && child.height[Native isNormal] yes: hc no: 1.0]
					]
					-> margin
					--> {
						if w? => left *= wc
						if h? => top *= hc
					}
				}
			}
		}]
	}


	;== Entrypoint

	on [main] {
		my app = Application[new]

		my window = Window[new]
		-> title = "MainWindow"
		-> width = 900.0
		-> height = 400.0
		-> background = SolidColorBrush[new: Color[r: 144 g: 144 b: 144]]
		-> windowStyle = WindowStyle.singleBorderWindow
		-> isTabStop = false
		-> renderTransformOrigin = Point[x: 0.5 y: 0.5]
		-> verticalAlignment = Vertical.bottom
		-> horizontalContentAlignment = Horiz.center
		-> verticalContentAlignment = Vertical.bottom

		This[buildWindow: window]

		app[run: window]
	}
}