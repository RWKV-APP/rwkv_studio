import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

extension Ext on File {
  String get name => path.split(Platform.pathSeparator).last;

  String get extension => path.split('.').last;

  Future<String> md5() => checksum(crypto.md5);

  Future<String> sha256() => checksum(crypto.sha256);

  Future<String> checksum(crypto.Hash hash) async {
    final accessFile = await open();
    final len = await accessFile.length();
    int chunkSize = 1024 * 1024;

    var output = StreamController<crypto.Digest>();
    var input = crypto.sha256.startChunkedConversion(output.sink);

    try {
      int offset = 0;
      while (offset < len) {
        int bytesToRead = (offset + chunkSize < len)
            ? chunkSize
            : (len - offset);
        List<int> buffer = await accessFile.read(bytesToRead);

        input.add(buffer);
        offset += bytesToRead;
      }

      input.close();
      return (await output.stream.single).toString();
    } finally {
      await accessFile.close();
    }
  }
}
