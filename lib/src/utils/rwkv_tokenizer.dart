import 'dart:convert';
import 'dart:io';

class RwkvTokenizer {
  static final Map<String, _TokenizerData> _cache = <String, _TokenizerData>{};

  final String vocabPath;

  static List<String> rwkvVocab20230424Data = [];

  const RwkvTokenizer({this.vocabPath = ''});

  static RwkvTokenizer get default_ => const RwkvTokenizer(vocabPath: '');

  int tokenCount(String text) {
    return encode(text).length;
  }

  List<int> encode(String text) {
    final _TokenizerData data = _getData();
    final List<int> bytes = utf8.encode(text);
    final List<int> tokens = <int>[];

    int index = 0;
    while (index < bytes.length) {
      _TrieNode? node = data.root.children[bytes[index]];
      if (node == null) {
        final int? fallback = data.singleByteToken[bytes[index]];
        if (fallback == null) {
          throw StateError('No token found for byte ${bytes[index]}');
        }
        tokens.add(fallback);
        index += 1;
        continue;
      }

      _TrieNode current = node;
      int? bestToken = current.token;
      int bestEnd = index + 1;
      int cursor = index + 1;
      while (cursor < bytes.length) {
        final _TrieNode? next = current.children[bytes[cursor]];
        if (next == null) {
          break;
        }
        current = next;
        cursor += 1;
        if (current.token != null) {
          bestToken = current.token;
          bestEnd = cursor;
        }
      }

      if (bestToken == null) {
        final int? fallback = data.singleByteToken[bytes[index]];
        if (fallback == null) {
          throw StateError('No token found for byte ${bytes[index]}');
        }
        tokens.add(fallback);
        index += 1;
        continue;
      }

      tokens.add(bestToken);
      index = bestEnd;
    }

    return tokens;
  }

  List<String> id2token(List<int> tokens) {
    final _TokenizerData data = _getData();
    final List<String> tokensStr = <String>[];
    for (final int token in tokens) {
      final t = data.tokenToBytes[token];
      if (t != null) {
        tokensStr.add(String.fromCharCodes(t));
      } else {
        throw StateError('No token found for id $token');
      }
    }
    return tokensStr;
  }

  String decode(List<int> tokens) {
    final _TokenizerData data = _getData();
    final List<int> bytes = <int>[];

    for (final int token in tokens) {
      final List<int>? chunk = data.tokenToBytes[token];
      if (chunk == null) {
        throw StateError('Unknown token id: $token');
      }
      bytes.addAll(chunk);
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  _TokenizerData _getData() {
    return _cache.putIfAbsent(vocabPath, () => _TokenizerData.load(vocabPath));
  }
}

class _TokenizerData {
  final _TrieNode root;
  final Map<int, List<int>> tokenToBytes;
  final Map<int, int> singleByteToken;

  _TokenizerData({
    required this.root,
    required this.tokenToBytes,
    required this.singleByteToken,
  });

  factory _TokenizerData.load(String path) {
    List<String> lines;

    if (path.isEmpty) {
      lines = RwkvTokenizer.rwkvVocab20230424Data;
    } else {
      final File file = File(path);
      if (!file.existsSync()) {
        throw FileSystemException('Tokenizer vocab file not found', path);
      }
      lines = file.readAsLinesSync();
    }

    final _TrieNode root = _TrieNode();
    final Map<int, List<int>> tokenToBytes = <int, List<int>>{};
    final Map<int, int> singleByteToken = <int, int>{};

    for (final String raw in lines) {
      final String line = raw.trim();
      if (line.isEmpty) {
        continue;
      }
      final _VocabEntry entry = _VocabEntry.parse(line);
      tokenToBytes[entry.token] = entry.bytes;
      if (entry.bytes.length == 1) {
        singleByteToken[entry.bytes.first] = entry.token;
      }
      _insert(root, entry.bytes, entry.token);
    }

    return _TokenizerData(
      root: root,
      tokenToBytes: tokenToBytes,
      singleByteToken: singleByteToken,
    );
  }

  static void _insert(_TrieNode root, List<int> bytes, int token) {
    _TrieNode node = root;
    for (final int value in bytes) {
      node = node.children.putIfAbsent(value, _TrieNode.new);
    }
    node.token = token;
  }
}

class _TrieNode {
  final Map<int, _TrieNode> children = <int, _TrieNode>{};
  int? token;
}

class _VocabEntry {
  final int token;
  final List<int> bytes;

  _VocabEntry({required this.token, required this.bytes});

  factory _VocabEntry.parse(String line) {
    final int firstSpace = line.indexOf(' ');
    if (firstSpace <= 0) {
      throw FormatException('Invalid vocab line: $line');
    }

    final int token = int.parse(line.substring(0, firstSpace));
    final int literalStart = line.indexOf("b'", firstSpace);
    final int literalEnd = line.lastIndexOf("' ");
    if (literalStart < 0 || literalEnd <= literalStart + 2) {
      throw FormatException('Invalid token bytes in line: $line');
    }

    final String literalBody = line.substring(literalStart + 2, literalEnd);
    final List<int> bytes = _parsePythonBytesLiteral(literalBody);
    return _VocabEntry(token: token, bytes: bytes);
  }

  static List<int> _parsePythonBytesLiteral(String text) {
    final List<int> out = <int>[];
    int i = 0;
    while (i < text.length) {
      final int code = text.codeUnitAt(i);
      if (code != 0x5c) {
        out.add(code);
        i += 1;
        continue;
      }

      if (i + 1 >= text.length) {
        throw FormatException('Invalid escape in bytes literal: $text');
      }
      final String esc = text[i + 1];
      switch (esc) {
        case 'x':
          if (i + 3 >= text.length) {
            throw FormatException('Invalid hex escape in bytes literal: $text');
          }
          final int value = int.parse(text.substring(i + 2, i + 4), radix: 16);
          out.add(value);
          i += 4;
          break;
        case 'n':
          out.add(0x0a);
          i += 2;
          break;
        case 'r':
          out.add(0x0d);
          i += 2;
          break;
        case 't':
          out.add(0x09);
          i += 2;
          break;
        case '\\':
          out.add(0x5c);
          i += 2;
          break;
        case "'":
          out.add(0x27);
          i += 2;
          break;
        case '"':
          out.add(0x22);
          i += 2;
          break;
        case 'a':
          out.add(0x07);
          i += 2;
          break;
        case 'b':
          out.add(0x08);
          i += 2;
          break;
        case 'f':
          out.add(0x0c);
          i += 2;
          break;
        case 'v':
          out.add(0x0b);
          i += 2;
          break;
        default:
          if (_isOctalDigit(esc)) {
            int end = i + 2;
            while (end < text.length &&
                end < i + 5 &&
                _isOctalDigit(text[end])) {
              end += 1;
            }
            out.add(int.parse(text.substring(i + 1, end), radix: 8));
            i = end;
            break;
          }
          out.add(esc.codeUnitAt(0));
          i += 2;
      }
    }
    return out;
  }

  static bool _isOctalDigit(String c) {
    final int v = c.codeUnitAt(0);
    return v >= 0x30 && v <= 0x37;
  }
}
