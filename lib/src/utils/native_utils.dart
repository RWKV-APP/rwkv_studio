import 'dart:io';

import 'package:rwkv_studio/src/errors/app_exception.dart';

class NativeUtils {
  static Future<void> showInFolder(String path) async {
    if (path.isEmpty) {
      throw const AppException.validation('Local path is empty');
    }

    final type = FileSystemEntity.typeSync(path);
    final directoryPath = switch (type) {
      FileSystemEntityType.directory => path,
      FileSystemEntityType.file => File(path).parent.path,
      _ => File(path).parent.path,
    };

    if (!Directory(directoryPath).existsSync()) {
      throw const AppException.validation('Folder not found');
    }
    try {
      if (Platform.isWindows) {
        if (type == FileSystemEntityType.file) {
          await Process.start('explorer.exe', ['/select,', path]);
        } else {
          await Process.start('explorer.exe', [directoryPath]);
        }
        return;
      }
      if (Platform.isMacOS) {
        if (type == FileSystemEntityType.file) {
          await Process.start('open', ['-R', path]);
        } else {
          await Process.start('open', [directoryPath]);
        }
        return;
      }
      if (Platform.isLinux) {
        await Process.start('xdg-open', [directoryPath]);
        return;
      }
      throw const AppException.validation(
        'Open folder is not supported on this platform',
      );
    } catch (e, s) {
      throw AppException.wrap(e, s);
    }
  }
}
