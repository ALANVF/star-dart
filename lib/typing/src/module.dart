import 'package:star/errors/errors.dart';
import 'package:star/util.dart';
import 'package:star/ast/src/ident.dart';

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

class Module extends Namespace {
	var isMain = false;
	Ident? native = null;

	Module({required super.span, required super.name, required super.params, required super.lookup});
	

	/* implements IDecl */

	String get declName => "module";
}