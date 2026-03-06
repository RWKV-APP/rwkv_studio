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
  final String albatrossPath;

  PythonSettingState({required this.selected, required this.albatrossPath});

  factory PythonSettingState.initial() => PythonSettingState(
    selected: '',
    albatrossPath: kIsWeb
        ? ''
        : pathJoin(appDataDir.path, 'rwkv_lightning'.joinPath('app.py')),
  );

  @override
  List<Object?> get props => [selected, albatrossPath];

  Map<String, dynamic> toMap() {
    return {'selected': selected, 'albatrossPath': albatrossPath};
  }

  factory PythonSettingState.fromMap(dynamic map) {
    if (map == null) {
      return PythonSettingState.initial();
    }
    return PythonSettingState(
      selected: map['selected'] ?? '',
      albatrossPath: map['albatrossPath'] ?? '',
    );
  }

  PythonSettingState copyWith({String? selected, String? albatrossPath}) {
    return PythonSettingState(
      selected: selected ?? this.selected,
      albatrossPath: albatrossPath ?? this.albatrossPath,
    );
  }
}
