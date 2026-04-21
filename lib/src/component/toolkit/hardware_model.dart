import 'product_model.dart';
import 'memory_1_model.dart';
import 'cpu_model.dart';
import 'gpu_model.dart';

@pragma("json_id:8a5cb68eb3c62436b1d0c67e746248be")
class HardwareModel {
  final ProductModel? product;
  final Memory1Model? memory;
  final CpuModel? cpu;
  final GpuModel? gpu;

  HardwareModel({
    this.product,
    this.memory,
    this.cpu,
    this.gpu,
  });

  factory HardwareModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return HardwareModel(
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'])
          : null,
      memory: json['memory'] != null
          ? Memory1Model.fromJson(json['memory'])
          : null,
      cpu: json['cpu'] != null ? CpuModel.fromJson(json['cpu']) : null,
      gpu: json['gpu'] != null ? GpuModel.fromJson(json['gpu']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product'] = product?.toJson();
    data['memory'] = memory?.toJson();
    data['cpu'] = cpu?.toJson();
    data['gpu'] = gpu?.toJson();
    return data;
  }

}
