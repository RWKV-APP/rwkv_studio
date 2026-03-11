import 'package:rwkv_studio/src/models/chat/chat_models.dart';

class ImportChatResult {}

class ExportChatUtils {
  ExportChatUtils._();

  static Future export(
    ConversationModel state,
    List<MessageModel> messages,
  ) async {
    throw 'Not implemented';
  }

  static Future<ImportChatResult> import(String path) async {
    throw 'Not implemented';
  }
}
