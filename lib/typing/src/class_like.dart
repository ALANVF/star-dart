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
import 'namespace.dart';

abstract class ClassLike extends Namespace {
	final members = <Member>[];
	final methods = <Method>[];
	final operators = <Operator>[];

	ClassLike({required super.span, required super.name, required super.lookup});


	/* implements IErrors */

	bool hasErrors() =>
		(  super.hasErrors()
		|| members.any((m) => m.hasErrors())
		|| methods.any((m) => m.hasErrors())
		|| operators.any((o) => o.hasErrors()));
	
	List<StarError> allErrors() => [
		...super.allErrors(),
		for(final m in members) ...m.allErrors(),
		for(final m in methods) ...m.allErrors(),
		for(final o in operators) ...o.allErrors(),
	];
}