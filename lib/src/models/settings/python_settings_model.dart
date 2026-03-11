import 'package:flutter/foundation.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';
import 'package:rwkv_studio/src/utils/path.dart';

class InterpreterModel extends Equatable {
  final String id;
  final String name;
  final String path;
  final bool isConda;

  @override
  List<Object?> get props => [id, name, path, isConda];

  InterpreterModel({
    required this.id,
    required this.path,
    required this.name,
    required this.isConda,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'path': path, 'name': name, 'isConda': isConda};
  }

  factory InterpreterModel.fromMap(Map<String, dynamic> map) {
    return InterpreterModel(
      id: map['id'] as String,
      path: map['path'] as String,
      name: map['name'] as String,
      isConda: map['isConda'] as bool,
    );
  }
}

class PythonSettingsModel extends Equatable {
  final String selected;
  final String albatrossPath;

  PythonSettingsModel({required this.selected, required this.albatrossPath});

  factory PythonSettingsModel.initial() => PythonSettingsModel(
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

  factory PythonSettingsModel.fromMap(dynamic map) {
    if (map == null) {
      return PythonSettingsModel.initial();
    }
    return PythonSettingsModel(
      selected: map['selected'] ?? '',
      albatrossPath: map['albatrossPath'] ?? '',
    );
  }

  PythonSettingsModel copyWith({String? selected, String? albatrossPath}) {
    return PythonSettingsModel(
      selected: selected ?? this.selected,
      albatrossPath: albatrossPath ?? this.albatrossPath,
    );
  }
}
