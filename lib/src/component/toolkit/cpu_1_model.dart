@pragma("json_id:8a7c9fcda3b315246df176950450ad4e")
class Cpu1Model {
  final int logicalCores;
  final num percent;
  final int physicalCores;

  Cpu1Model({
    required this.logicalCores,
    required this.percent,
    required this.physicalCores,
  });

  factory Cpu1Model.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return Cpu1Model(
      logicalCores: json['logical_cores'] ?? 0,
      percent: json['percent'] ?? 0,
      physicalCores: json['physical_cores'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['logical_cores'] = logicalCores;
    data['percent'] = percent;
    data['physical_cores'] = physicalCores;
    return data;
  }

}
