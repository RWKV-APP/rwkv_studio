part of 'app_cubit.dart';

class HardwareInfoState extends Equatable {
  final num memTotal;
  final num memFree;
  final num memProcessPercent;
  final num cpuPercent;
  final num cpuProcessPercent;

  num get memUsed => memTotal - memFree;

  num get memUsedPercent => memUsed / memTotal;

  num get memProcessUsed => memTotal * (memProcessPercent / 100);

  const HardwareInfoState({
    required this.memTotal,
    required this.memFree,
    required this.memProcessPercent,
    required this.cpuPercent,
    required this.cpuProcessPercent,
  });

  static const empty = HardwareInfoState(
    memTotal: 0,
    memFree: 0,
    memProcessPercent: 0,
    cpuPercent: 0,
    cpuProcessPercent: 0,
  );

  @override
  List<Object?> get props => [
    memTotal,
    memFree,
    memProcessPercent,
    cpuPercent,
    cpuProcessPercent,
  ];

  HardwareInfoState copyWith({
    num? memTotal,
    num? memFree,
    num? memProcessPercent,
    num? cpuPercent,
    num? cpuProcessPercent,
  }) {
    return HardwareInfoState(
      memTotal: memTotal ?? this.memTotal,
      memFree: memFree ?? this.memFree,
      memProcessPercent: memProcessPercent ?? this.memProcessPercent,
      cpuPercent: cpuPercent ?? this.cpuPercent,
      cpuProcessPercent: cpuProcessPercent ?? this.cpuProcessPercent,
    );
  }
}
