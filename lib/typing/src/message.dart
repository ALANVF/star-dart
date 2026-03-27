import 'package:freezed_annotation/freezed_annotation.dart';

import 'expr.dart';
import 'type.dart';

part 'message.freezed.dart';

@freezed
sealed class Message<T> with _$Message<T> {
	final Type? category;

	Message._({required this.category});
	
	factory Message.single(String name, {required Type? category}) = MSingle<T>;
	factory Message.multi(List<String> labels, TExprs exprs, {required Type? category}) = MMulti<T>;
	static Message<TExpr> cast(Type type, {required Type? category}) => MCast(type, category: category);
}

class MCast extends Message<TExpr> {
	final Type type;
	MCast(this.type, {required Type? category}): super._(category: category);
}