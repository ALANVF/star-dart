import 'package:star/util.dart';

import 'category.dart';
import 'ctx.dart';
import 'any_type_decl.dart';
import 'cache.dart';
import 'lookup_path.dart';
import 'type.dart';
import 'type_path.dart';
import 'star_unit.dart';
import 'star_file.dart';
import 'traits.dart';

import "dart:io" as io;
import "package:path/path.dart" show basename;


String _toName(String name) {
	if(name.contains(r"[+()\[\]]")) {
		return name.matchAsPrefix(r"\(?(\w+)")!.group(1)!;
	} else {
		return name;
	}
}

abstract class StarDir implements ITypeLookup {
	final String name;
	final String path;
	List<StarUnit> units = [];
	List<StarFile> files = [];

	StarDir({required this.name, required this.path});

	void buildUnits() {
		this.addNestedNames(io.Directory(path));
	}

	void addNestedNames(io.Directory dir) {
		final entries = <String, (io.File?, io.Directory?)>{};

		for(final entry in dir.listSync()) {
			switch(entry) {
				case io.File f:
					final b = basename(f.path);
					if(b.endsWith(".star")) {
						final name = b.substring(0, b.length-1-5);

						if(entries[name]?.$1 == null) {
							entries[name] = (f, entries[name]?.$2);
						}
					}
				
				case io.Directory d:
					final b = basename(d.path);
					if(!b.charAt(0).isLower()) {
						final name = b;

						if(entries[name]?.$2 == null) {
							entries[name] = (entries[name]?.$1, d);
						}
					}
			}
		}

		for(final MapEntry(:key, :value) in entries.entries) {
			this.addName(key, value.$1, value.$2);
		}
	}

	void addName(String name, io.File? file, io.Directory? dir) {
		if(name.charAt(0).isLower()) {
			if(file != null) {
				throw 'Invalid file $name.star in directory $path';
			} else if(dir != null) {
				this.addNestedNames(dir);
			}
		}

		if(file != null && dir == null) {
			this.files.add(StarFile(this, file.path));
		} else if(dir != null) {
			final unit = StarUnit(
				name: _toName(name),
				path: path,
				outer: this
			);

			if(file != null) {
				unit.primary = StarFile(this, file.path, unit);
			}

			unit.addNestedNames(dir);
		}
	}

	void gatherFiles(List<StarFile> gather) {
		gather.addAll(files);

		for(final unit in units) unit.gatherFiles(gather);
	}


	/* implements ITypeLookup */

	Type makeTypePath(TypePath path) => path.toType(this);

	Type? findType(LookupPath path, Search search, AnyTypeDecl? from, [int depth = 0, Cache cache = const Cache.empty()]) => throw "todo";

	Category? findCategory(Ctx ctx, Type cat, Type forType, AnyTypeDecl? from, [Cache cache = const Cache.empty()]) => throw "todo";
}