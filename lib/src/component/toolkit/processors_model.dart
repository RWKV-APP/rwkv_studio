@pragma("json_id:dd1111e34cde9b08e6b122c2eb7dd4bd")
class ProcessorsModel {
  final dynamic capabilities;
  final dynamic cores;
  final int totalHardwareThreads;
  final String vendor;
  final int totalThreads;
  final int totalCores;
  final String model;
  final int id;

  ProcessorsModel({
    required this.capabilities,
    required this.cores,
    required this.totalHardwareThreads,
    required this.vendor,
    required this.totalThreads,
    required this.totalCores,
    required this.model,
    required this.id,
  });

  factory ProcessorsModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return ProcessorsModel(
      capabilities: json['capabilities'],
      cores: json['cores'],
      totalHardwareThreads: json['total_hardware_threads'] ?? 0,
      vendor: json['vendor'] ?? '',
      totalThreads: json['total_threads'] ?? 0,
      totalCores: json['total_cores'] ?? 0,
      model: json['model'] ?? '',
      id: json['id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['capabilities'] = capabilities;
    data['cores'] = cores;
    data['total_hardware_threads'] = totalHardwareThreads;
    data['vendor'] = vendor;
    data['total_threads'] = totalThreads;
    data['total_cores'] = totalCores;
    data['model'] = model;
    data['id'] = id;
    return data;
  }

}
