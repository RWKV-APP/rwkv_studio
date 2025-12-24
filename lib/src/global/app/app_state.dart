part of 'app_cubit.dart';

class AppState {
  final List<dynamic> errors;
  final FluentThemeData theme;

  AppState({required this.errors, required this.theme});

  factory AppState.initial() {
    return AppState(errors: [], theme: FluentThemeData.light());
  }

  AppState copyWith({List<dynamic>? errors, FluentThemeData? theme}) {
    return AppState(errors: errors ?? this.errors, theme: theme ?? this.theme);
  }
}
