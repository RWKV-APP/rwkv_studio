import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';

class ImportChatResult {}

class ExportChatUtils {
  ExportChatUtils._();

  static Future export(
    ConversationState state,
    List<MessageState> messages,
  ) async {
    throw 'Not implemented';
  }

  static Future<ImportChatResult> import(String path) async {
    throw 'Not implemented';
  }
}
