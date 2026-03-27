
import 'star_dir.dart';
import 'star_file.dart';


sealed class StarUnit extends StarDir {
	StarDir outer;
	StarFile? primary;

	StarUnit({required super.name, required super.path, required super.units, required super.files,
				required this.outer, required this.primary});
}