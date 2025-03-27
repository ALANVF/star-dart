import 'package:star/util.dart';
import 'package:star/text/text.dart';
import 'stmt.dart';
import 'decl.dart';

class EmptyMethodAttrs {
	Span? isStatic;
}

abstract class EmptyMethod extends Decl {
	final EmptyMethodAttrs attrs;
	final StmtBody body;

	EmptyMethod(super.span, this.attrs, {required this.body});
}

class DefaultInit extends EmptyMethod {
	DefaultInit(super.span, super.attrs, {required super.body});

	String get displayName => attrs.isStatic == null ? "default initializer" : "static initializer";
}

class Deinit extends EmptyMethod {
	Deinit(super.span, super.attrs, {required super.body});

	String get displayName => attrs.isStatic == null ? "default deinitializer" : "static deinitializer";
}