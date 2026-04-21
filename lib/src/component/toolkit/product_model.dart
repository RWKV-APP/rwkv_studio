@pragma("json_id:9b868aed613bd74032f08ffe7404a82c")
class ProductModel {
  final String vendor;
  final String name;
  final String serialNumber;
  final String family;
  final String sku;
  final String uuid;
  final String version;

  ProductModel({
    required this.vendor,
    required this.name,
    required this.serialNumber,
    required this.family,
    required this.sku,
    required this.uuid,
    required this.version,
  });

  factory ProductModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return ProductModel(
      vendor: json['vendor'] ?? '',
      name: json['name'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      family: json['family'] ?? '',
      sku: json['sku'] ?? '',
      uuid: json['uuid'] ?? '',
      version: json['version'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['vendor'] = vendor;
    data['name'] = name;
    data['serial_number'] = serialNumber;
    data['family'] = family;
    data['sku'] = sku;
    data['uuid'] = uuid;
    data['version'] = version;
    return data;
  }

}
