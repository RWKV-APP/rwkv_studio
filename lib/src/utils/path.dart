import 'dart:io';

Directory? _appDataDir;

set appDataDir(Directory dir) => _appDataDir = dir;

Directory get appDataDir =>
    _appDataDir ?? File(Platform.resolvedExecutable).parent;

String pathJoin(String a, String b) {
  if (Platform.isWindows) {
    return [a, b].join('\\');
  }
  return [a, b].join('/');
}

String fileName(String path) {
  return path.split(Platform.pathSeparator).last;
}

extension DirectoryPath on Directory {
  String get fileName => path.split(Platform.pathSeparator).last;

  Directory childDirectory(String name) => Directory(pathJoin(path, name));

  File childFile(String name) => File(pathJoin(path, name));

  bool isAppPrivate() {
    final appData = appDataDir.absolute.path;
    final current = absolute.path;
    return current == appData ||
        current.startsWith('$appData${Platform.pathSeparator}');
  }
}

extension StringPath on String {
  String get fileName => split(Platform.pathSeparator).last;

  String joinPath(String other) => pathJoin(this, other);
}
