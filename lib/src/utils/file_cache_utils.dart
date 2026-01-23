import 'dart:convert';
import 'dart:io';

class FileCacheUtils {
  FileCacheUtils._();

  static Future<void> saveFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  static Future<String> readFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return '';
    }
    return await file.readAsString();
  }

  static Future saveMap(String path, Map<String, dynamic> map) async {
    final json = jsonEncode(map);
    await saveFile(path, json);
  }

  static Future<Map<String, dynamic>> readMap(String path) async {
    final json = await readFile(path);
    if (json.isEmpty) {
      return {};
    }
    return jsonDecode(json);
  }
}
