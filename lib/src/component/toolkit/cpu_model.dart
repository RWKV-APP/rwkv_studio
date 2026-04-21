import 'processors_model.dart';

@pragma("json_id:d0e0956f71c31016f36b0c87b5d35b48")
class CpuModel {
  final int totalHardwareThreads;
  final int totalThreads;
  final int totalCores;
  final List<ProcessorsModel> processors;

  CpuModel({
    required this.totalHardwareThreads,
    required this.totalThreads,
    required this.totalCores,
    required this.processors,
  });

  factory CpuModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return CpuModel(
      totalHardwareThreads: json['total_hardware_threads'] ?? 0,
      totalThreads: json['total_threads'] ?? 0,
      totalCores: json['total_cores'] ?? 0,
      processors: (json['processors'] as Iterable?)?.map((e) =>
          ProcessorsModel.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_hardware_threads'] = totalHardwareThreads;
    data['total_threads'] = totalThreads;
    data['total_cores'] = totalCores;
    data['processors'] = processors.map((e) => e.toJson()).toList();
    return data;
  }

}
