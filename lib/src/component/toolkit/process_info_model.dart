@pragma("json_id:b6ba94cd12aab09939529bc518a79196")
class ProcessInfoModel {
  final int rss;
  final num memoryPercent;
  final String name;
  final int pid;
  final int vms;
  final num cpuPercent;

  ProcessInfoModel({
    required this.rss,
    required this.memoryPercent,
    required this.name,
    required this.pid,
    required this.vms,
    required this.cpuPercent,
  });

  factory ProcessInfoModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return ProcessInfoModel(
      rss: json['rss'] ?? 0,
      memoryPercent: json['memory_percent'] ?? 0,
      name: json['name'] ?? '',
      pid: json['pid'] ?? 0,
      vms: json['vms'] ?? 0,
      cpuPercent: json['cpu_percent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rss'] = rss;
    data['memory_percent'] = memoryPercent;
    data['name'] = name;
    data['pid'] = pid;
    data['vms'] = vms;
    data['cpu_percent'] = cpuPercent;
    return data;
  }

}
