part of 'app_cubit.dart';

class HardwareInfoState extends Equatable {
  final List<PciModel> gpus;
  final num memTotal;
  final num memFree;
  final num memProcessPercent;
  final num cpuPercent;
  final num cpuProcessPercent;

  num get memUsed => memTotal - memFree;

  num get memUsedPercent => memUsed / memTotal;

  num get memProcessUsed => memTotal * (memProcessPercent / 100);

  bool get hasNvidiaGPU => gpus.any(
    (gpu) => gpu.product?.name.toLowerCase().contains('nvidia') == true,
  );

  bool get hasIntelGPU => gpus.any(
    (gpu) => gpu.product?.name.toLowerCase().contains('intel') == true,
  );

  bool get hasAmdGPU => gpus.any(
    (gpu) => gpu.product?.name.toLowerCase().contains('amd') == true,
  );

  const HardwareInfoState({
    required this.memTotal,
    required this.memFree,
    required this.memProcessPercent,
    required this.cpuPercent,
    required this.cpuProcessPercent,
    required this.gpus,
  });

  static const empty = HardwareInfoState(
    memTotal: 0,
    memFree: 0,
    memProcessPercent: 0,
    cpuPercent: 0,
    cpuProcessPercent: 0,
    gpus: [],
  );

  @override
  List<Object?> get props => [
    memTotal,
    memFree,
    memProcessPercent,
    cpuPercent,
    cpuProcessPercent,
    gpus,
  ];

  HardwareInfoState copyWith({
    num? memTotal,
    num? memFree,
    num? memProcessPercent,
    num? cpuPercent,
    num? cpuProcessPercent,
    List<PciModel>? gpus,
  }) {
    return HardwareInfoState(
      memTotal: memTotal ?? this.memTotal,
      memFree: memFree ?? this.memFree,
      memProcessPercent: memProcessPercent ?? this.memProcessPercent,
      cpuPercent: cpuPercent ?? this.cpuPercent,
      cpuProcessPercent: cpuProcessPercent ?? this.cpuProcessPercent,
      gpus: gpus ?? this.gpus,
    );
  }
}
