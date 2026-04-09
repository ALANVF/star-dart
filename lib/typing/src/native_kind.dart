import 'package:freezed_annotation/freezed_annotation.dart';

import 'traits.dart';
import 'type.dart';

part 'native_kind.freezed.dart';


@freezed
sealed class NativeKind with _$NativeKind { NativeKind._();
	factory NativeKind.void_() = NVoid;
	factory NativeKind.bool() = NBool;
	factory NativeKind.int8() = NInt8;
	factory NativeKind.uint8() = NUInt8;
	factory NativeKind.int16() = NInt16;
	factory NativeKind.uint16() = NUInt16;
	factory NativeKind.int32() = NInt32;
	factory NativeKind.uint32() = NUInt32;
	factory NativeKind.int64() = NInt64;
	factory NativeKind.uint64() = NUInt64;
	factory NativeKind.float32() = NFloat32;
	factory NativeKind.float64() = NFloat64;
	factory NativeKind.dec64() = NDec64;
	factory NativeKind.voidPtr() = NVoidPtr;
	factory NativeKind.ptr(Type t) = NPtr;
}

/*
function matches(self: NativeKind, other: NativeKind) return self._match(
	at(NPtr(t)) => other._match(
		at(NPtr(t2)) => t.hasParentType(t2) || t.hasChildType(t2),
		_ => false
	),
	_ => self == other
);*/