import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:star/text/src/span.dart';

part 'type.freezed.dart';

@freezed
sealed class Type with _$Type { Type._();
	factory Type.blank({Span? span}) = TBlank;

	String get simpleName => "TODO";
}