import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:rwkv_studio/src/utils/path.dart';

class ArchiveUtils {
  static Stream<String> extractZip({
    required String path,
    required String outDir,
  }) async* {
    // Use an InputFileStream to access the zip file without storing it in memory.
    // Note that using InputFileStream will result in an error from the web platform
    // as there is no file system there.
    final inputStream = InputFileStream(path);
    // Decode the zip from the InputFileStream. The archive will have the contents of the
    // zip, without having stored the data in memory.
    final archive = ZipDecoder().decodeStream(inputStream);
    final symbolicLinks =
        []; // keep a list of the symbolic link entities, if any.
    // For all of the entries in the archive
    for (final file in archive) {
      // You should create symbolic links **after** the rest of the archive has been
      // extracted, otherwise the file being linked might not exist yet.
      if (file.isSymbolicLink) {
        symbolicLinks.add(file);
        continue;
      }
      if (file.isFile) {
        // Write the file content to a directory called 'out'.
        // In practice, you should make sure file.name doesn't include '..' paths
        // that would put it outside of the extraction directory.
        // An OutputFileStream will write the data to disk.
        final outputStream = OutputFileStream(pathJoin(outDir, file.name));
        // The writeContent method will decompress the file content directly to disk without
        // storing the decompressed data in memory.
        file.writeContent(outputStream);
        // Make sure to close the output stream so the File is closed.
        outputStream.closeSync();
      } else {
        // If the entity is a directory, create it. Normally writing a file will create
        // the directories necessary, but sometimes an archive will have an empty directory
        // with no files.
        Directory(pathJoin(outDir, file.name)).createSync(recursive: true);
      }
    }
    // Create symbolic links **after** the rest of the archive has been extracted to make sure
    // the file being linked exists.
    for (final entity in symbolicLinks) {
      // Before using this in production code, you should ensure the symbolicLink path
      // points to a file within the archive, otherwise it could be a security issue.
      final p = pathJoin(outDir, entity.fullPathName);
      final link = Link(p);
      link.createSync(entity.symbolicLink!, recursive: true);
    }
  }
}
