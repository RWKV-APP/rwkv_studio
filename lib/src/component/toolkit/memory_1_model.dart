import 'modules_model.dart';

@pragma("json_id:cb73341a2b6be42879d6032fe76bf779")
class Memory1Model {
  final num totalUsableBytes;
  final int defaultHugePageSize;
  final int totalHugePageBytes;
  final num totalPhysicalBytes;
  final dynamic hugePageAmountsBySize;
  final dynamic supportedPageSizes;
  final List<ModulesModel> modules;

  Memory1Model({
    required this.totalUsableBytes,
    required this.defaultHugePageSize,
    required this.totalHugePageBytes,
    required this.totalPhysicalBytes,
    required this.hugePageAmountsBySize,
    required this.supportedPageSizes,
    required this.modules,
  });

  factory Memory1Model.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return Memory1Model(
      totalUsableBytes: json['total_usable_bytes'] ?? 0,
      defaultHugePageSize: json['default_huge_page_size'] ?? 0,
      totalHugePageBytes: json['total_huge_page_bytes'] ?? 0,
      totalPhysicalBytes: json['total_physical_bytes'] ?? 0,
      hugePageAmountsBySize: json['huge_page_amounts_by_size'],
      supportedPageSizes: json['supported_page_sizes'],
      modules: (json['modules'] as Iterable?)?.map((e) =>
          ModulesModel.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_usable_bytes'] = totalUsableBytes;
    data['default_huge_page_size'] = defaultHugePageSize;
    data['total_huge_page_bytes'] = totalHugePageBytes;
    data['total_physical_bytes'] = totalPhysicalBytes;
    data['huge_page_amounts_by_size'] = hugePageAmountsBySize;
    data['supported_page_sizes'] = supportedPageSizes;
    data['modules'] = modules.map((e) => e.toJson()).toList();
    return data;
  }

}
