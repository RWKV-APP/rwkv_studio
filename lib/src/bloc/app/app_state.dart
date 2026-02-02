part of 'app_cubit.dart';

class AppState {
  final int pane;
  final List<Python> pythons;
  final String selectedPythonId;

  AppState({
    required this.pane,
    required this.pythons,
    required this.selectedPythonId,
  });

  factory AppState.initial() {
    return AppState(pane: 0, pythons: [], selectedPythonId: '');
  }

  AppState copyWith({
    int? pane,
    List<Python>? pythons,
    String? selectedPythonId,
  }) {
    return AppState(
      pane: pane ?? this.pane,
      pythons: pythons ?? this.pythons,
      selectedPythonId: selectedPythonId ?? this.selectedPythonId,
    );
  }
}
