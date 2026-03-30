import 'package:star/errors/errors.dart';
import 'package:star/util.dart';

import 'category.dart';
import 'ctx.dart';
import 'lookup_path.dart';
import 'traits.dart';
import 'type.dart';
import 'any_type_decl.dart';
import 'typevar.dart';
import 'cache.dart';
import 'type_path.dart';
import 'member.dart';
import 'any_method.dart';
import 'operator.dart';
import 'class_like.dart';

abstract class Kind extends ClassLike {
	Deinit? deinit = null;
	var isFlags = false;
	var isStrong = false;
	var isUncounted = false;

	Kind({required super.span, required super.name, required super.params, required super.lookup});
}