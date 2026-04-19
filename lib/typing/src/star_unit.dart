
import 'star_dir.dart';
import 'star_file.dart';


class StarUnit extends StarDir {
	StarDir outer;
	StarFile? primary;

	StarUnit({required super.name, required super.path,
				required this.outer});
	

	/* extends StarDir */

	@override
	void gatherFiles(List<StarFile> gather) {
		if(primary != null) gather.add(primary!);
		super.gatherFiles(gather);
	}
}