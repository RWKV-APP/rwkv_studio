@pragma("json_id:0c01b6b23836bf6edeaf8e2091cdd111")
class ModulesModel {
  final num sizeBytes;
  final String vendor;
  final String location;
  final String serialNumber;
  final String label;

  ModulesModel({
    required this.sizeBytes,
    required this.vendor,
    required this.location,
    required this.serialNumber,
    required this.label,
  });

  factory ModulesModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return ModulesModel(
      sizeBytes: json['size_bytes'] ?? 0,
      vendor: json['vendor'] ?? '',
      location: json['location'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['size_bytes'] = sizeBytes;
    data['vendor'] = vendor;
    data['location'] = location;
    data['serial_number'] = serialNumber;
    data['label'] = label;
    return data;
  }

}
