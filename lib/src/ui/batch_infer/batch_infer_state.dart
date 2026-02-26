part of 'batch_infer_cubit.dart';

class BatchSizeState {
  final int row;
  final int col;

  static BatchSizeState get default_ => all[1];

  static List<BatchSizeState> get all {
    return [
      const BatchSizeState(row: 4, col: 4),
      const BatchSizeState(row: 8, col: 12),
      const BatchSizeState(row: 16, col: 30),
      const BatchSizeState(row: 32, col: 56),
      const BatchSizeState(row: 64, col: 90),
      const BatchSizeState(row: 80, col: 80),
      const BatchSizeState(row: 90, col: 90),
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

class BatchInferState {
  final BatchSizeState setting;
  final ModelLoadState modelState;
  final TextEditingController textController;
  final List<String> cells;
  final bool isRunning;

  const BatchInferState({
    required this.setting,
    required this.modelState,
    required this.textController,
    required this.cells,
    required this.isRunning,
  });

  factory BatchInferState.empty() {
    final setting = BatchSizeState.default_;
    return BatchInferState(
      setting: setting,
      modelState: ModelLoadState.empty(),
      textController: TextEditingController(),
      cells: [for (var i = 0; i < setting.size; i++) '-'],
      isRunning: false,
    );
  }

  BatchInferState copyWith({
    ModelLoadState? modelState,
    BatchSizeState? setting,
    TextEditingController? textController,
    List<String>? cells,
    bool? isRunning,
  }) {
    return BatchInferState(
      setting: setting ?? this.setting,
      modelState: modelState ?? this.modelState,
      textController: textController ?? this.textController,
      cells: cells ?? this.cells,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}
