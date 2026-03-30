import 'star_dir.dart';
import 'star_file.dart';

class StarProject extends StarDir {
	static StarProject? STDLIB = null;

	StarFile? main;
	bool useStdlib;

	StarProject({required super.name, required super.path, required super.units, required super.files,
				required this.main, required this.useStdlib});
}