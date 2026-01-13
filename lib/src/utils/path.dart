import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> appDocumentsDir() => getApplicationDocumentsDirectory().then(
  (value) => Directory(pathJoin(value.path, 'rwkv_music')).path,
);

Directory get appExecutableDir => File(Platform.resolvedExecutable).parent;

String pathJoin(String a, String b) {
  if (Platform.isWindows) {
    return '$a\\$b';
  }
  return '$a/$b';
}

String fileName(String path) {
  return path.split(Platform.pathSeparator).last;
}

extension StringPath on String {
  String get fileName => split(Platform.pathSeparator).last;

  String joinPath(String other) => pathJoin(this, other);
}
