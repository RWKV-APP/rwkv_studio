import 'package:rwkv_studio/src/component/toolkit/process_info_model.dart';

import 'memory_model.dart';
import 'cpu_1_model.dart';

@pragma("json_id:a854592d539507bdfd62473c893bcdc0")
class HardwareUsageModel {
  final MemoryModel? memory;
  final Cpu1Model? cpu;
  final ProcessInfoModel? process;

  HardwareUsageModel({
    this.memory,
    this.cpu,
    this.process,
  });

  factory HardwareUsageModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return HardwareUsageModel(
      memory: json['memory'] != null
          ? MemoryModel.fromJson(json['memory'])
          : null,
      cpu: json['cpu'] != null ? Cpu1Model.fromJson(json['cpu']) : null,
      process: json['process'] != null ? ProcessInfoModel.fromJson(json['process']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['memory'] = memory?.toJson();
    data['cpu'] = cpu?.toJson();
    data['process'] = process?.toJson();
    return data;
  }

}
