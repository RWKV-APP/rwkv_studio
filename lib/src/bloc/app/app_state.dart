part of 'app_cubit.dart';

class AppState {
  final int pane;

  AppState({required this.pane});

  factory AppState.initial() {
    return AppState(pane: 2);
  }

  AppState copyWith({int? pane}) {
    return AppState(pane: pane ?? this.pane);
  }
}
