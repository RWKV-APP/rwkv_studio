@pragma("json_id:cd28f889041186f2f7a2407607b64690")
class MemoryModel {
  final num total;
  final num available;
  final int usedPercent;
  final num used;
  final num free;

  MemoryModel({
    required this.total,
    required this.available,
    required this.usedPercent,
    required this.used,
    required this.free,
  });

  factory MemoryModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return MemoryModel(
      total: json['total'] ?? 0,
      available: json['available'] ?? 0,
      usedPercent: json['used_percent'] ?? 0,
      used: json['used'] ?? 0,
      free: json['free'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    data['available'] = available;
    data['used_percent'] = usedPercent;
    data['used'] = used;
    data['free'] = free;
    return data;
  }

}
