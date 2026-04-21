@pragma("json_id:e10e4270396d51f26046f2f2bb3d0bb9")
class VendorModel {
  final String name;
  final String id;

  VendorModel({
    required this.name,
    required this.id,
  });

  factory VendorModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return VendorModel(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['id'] = id;
    return data;
  }

}
