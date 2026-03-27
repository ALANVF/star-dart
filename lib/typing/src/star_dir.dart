import 'star_unit.dart';
import 'star_file.dart';


abstract class StarDir {
	final String name;
	final String path;
	final List<StarUnit> units;
	final List<StarFile> files;

	StarDir({required this.name, required this.path, required this.units, required this.files});
}