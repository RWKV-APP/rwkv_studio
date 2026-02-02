part of 'setting_cubit.dart';

class InterpreterState {
  final String path;

  InterpreterState({required this.path});

  Map<String, dynamic> toMap() {
    return {'path': path};
  }

  factory InterpreterState.fromMap(Map<String, dynamic> map) {
    return InterpreterState(path: map['path'] as String);
  }
}

class PythonSettingState extends Equatable {
  final List<InterpreterState> interpreters;
  final String selected;

  PythonSettingState({required this.interpreters, required this.selected});

  factory PythonSettingState.initial() =>
      PythonSettingState(interpreters: [], selected: '');

  @override
  List<Object?> get props => [interpreters, selected];

  Map<String, dynamic> toMap() {
    return {
      'interpreters': interpreters.map((e) => e.toMap()).toList(),
      'selected': selected,
    };
  }

  factory PythonSettingState.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return PythonSettingState.initial();
    }
    return PythonSettingState(
      interpreters: (map['interpreters'] as Iterable)
          .map((e) => InterpreterState.fromMap(e))
          .toList(),
      selected: map['selected'] as String,
    );
  }
}
