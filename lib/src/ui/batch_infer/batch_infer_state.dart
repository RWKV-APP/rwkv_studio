part of 'batch_infer_cubit.dart';

class BatchSizeState {
  final int row;
  final int col;

  static BatchSizeState get default_ => all[1];

  static List<BatchSizeState> get all {
    return [
      const BatchSizeState(row: 4, col: 4),
      const BatchSizeState(row: 8, col: 12),
      const BatchSizeState(row: 12, col: 20),
      const BatchSizeState(row: 16, col: 30),
      const BatchSizeState(row: 22, col: 34),
      const BatchSizeState(row: 32, col: 42),
      // const BatchSizeState(row: 64, col: 90),
      // const BatchSizeState(row: 80, col: 80),
      // const BatchSizeState(row: 90, col: 90),
    ];
  }

  const BatchSizeState({required this.row, required this.col});

  factory BatchSizeState.empty() {
    return const BatchSizeState(row: 4, col: 4);
  }

  int get size {
    return row * col;
  }
}

class PerformanceState {
  final double tps;

  const PerformanceState({required this.tps});
}

class BatchInferState {
  final PerformanceState performance;
  final BatchSizeState setting;
  final ModelLoadState modelState;
  final TextEditingController textController;
  final List<String> cells;
  final bool isRunning;
  final bool showSettingPanel;
  final String decodeParamId;

  const BatchInferState({
    required this.setting,
    required this.modelState,
    required this.showSettingPanel,
    required this.textController,
    required this.cells,
    required this.isRunning,
    required this.performance,
    required this.decodeParamId,
  });

  factory BatchInferState.empty() {
    final setting = BatchSizeState.default_;
    return BatchInferState(
      setting: setting,
      modelState: ModelLoadState.empty(),
      textController: TextEditingController(text: '在很久很久以前'),
      cells: [for (var i = 0; i < setting.size; i++) '-'],
      isRunning: false,
      showSettingPanel: false,
      performance: const PerformanceState(tps: 0.0),
      decodeParamId: '',
    );
  }

  BatchInferState copyWith({
    ModelLoadState? modelState,
    BatchSizeState? setting,
    TextEditingController? textController,
    List<String>? cells,
    bool? showSettingPanel,
    PerformanceState? performance,
    bool? isRunning,
    String? decodeParamId,
  }) {
    return BatchInferState(
      setting: setting ?? this.setting,
      modelState: modelState ?? this.modelState,
      textController: textController ?? this.textController,
      showSettingPanel: showSettingPanel ?? this.showSettingPanel,
      cells: cells ?? this.cells,
      isRunning: isRunning ?? this.isRunning,
      performance: performance ?? this.performance,
      decodeParamId: decodeParamId ?? this.decodeParamId,
    );
  }
}
