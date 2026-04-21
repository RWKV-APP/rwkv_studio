import 'usage_model.dart';
import 'hardware_model.dart';

@pragma("json_id:cbde2d9e0039624dcade0205bad18e9a")
class HardwareInfoModel {
  final HardwareUsageModel? usage;
  final HardwareModel? hardware;

  HardwareInfoModel({
    this.usage,
    this.hardware,
  });

  factory HardwareInfoModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return HardwareInfoModel(
      usage: json['usage'] != null ? HardwareUsageModel.fromJson(json['usage']) : null,
      hardware: json['hardware'] != null ? HardwareModel.fromJson(
          json['hardware']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['usage'] = usage?.toJson();
    data['hardware'] = hardware?.toJson();
    return data;
  }

}
