import 'package:hive_ce/hive.dart';

part 'state_cache_box.g.dart';

@HiveType(typeId: 6)
class StateCacheBox {
  @HiveField(0)
  Map<String, dynamic> decodeParamPresets;

  StateCacheBox({required this.decodeParamPresets});
}
