import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:rwkv_studio/src/utils/path.dart';

class ArchiveUtils {
  static Stream<String> extractZip({
    required String path,
    required String outDir,
  }) async* {
    final inputStream = InputFileStream(path);
    try {
      final archive = ZipDecoder().decodeStream(inputStream);
      final symbolicLinks =
          []; // keep a list of the symbolic link entities, if any.
      for (final file in archive) {
        if (file.isSymbolicLink) {
          symbolicLinks.add(file);
          continue;
        }
        if (file.isFile) {
          final outputStream = OutputFileStream(pathJoin(outDir, file.name));
          file.writeContent(outputStream);
          outputStream.closeSync();
        } else {
          Directory(pathJoin(outDir, file.name)).createSync(recursive: true);
        }
      }
      for (final entity in symbolicLinks) {
        final p = pathJoin(outDir, entity.fullPathName);
        final link = Link(p);
        link.createSync(entity.symbolicLink!, recursive: true);
      }
    } finally {
      inputStream.close();
    }
    yield "success";
  }
}
