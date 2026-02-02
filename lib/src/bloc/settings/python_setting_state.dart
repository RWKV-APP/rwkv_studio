part of 'setting_cubit.dart';

class InterpreterState extends Equatable {
  final String id;
  final String name;
  final String path;
  final bool isConda;

  @override
  List<Object?> get props => [id, name, path, isConda];

  InterpreterState({
    required this.id,
    required this.path,
    required this.name,
    required this.isConda,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'path': path, 'name': name, 'isConda': isConda};
  }

  factory InterpreterState.fromMap(Map<String, dynamic> map) {
    return InterpreterState(
      id: map['id'] as String,
      path: map['path'] as String,
      name: map['name'] as String,
      isConda: map['isConda'] as bool,
    );
  }
}

class PythonSettingState extends Equatable {
  final String selected;

  PythonSettingState({required this.selected});

  factory PythonSettingState.initial() => PythonSettingState(selected: '');

  @override
  List<Object?> get props => [selected];

  Map<String, dynamic> toMap() {
    return {'selected': selected};
  }

  factory PythonSettingState.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return PythonSettingState.initial();
    }
    return PythonSettingState(selected: map['selected'] as String);
  }

  PythonSettingState copyWith({String? selected}) {
    return PythonSettingState(selected: selected ?? this.selected);
  }
}
