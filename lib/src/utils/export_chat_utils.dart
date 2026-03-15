import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/chat/chat_models.dart';

class ImportChatResult {}

class ExportChatUtils {
  ExportChatUtils._();

  static Future export(
    ConversationModel state,
    List<MessageModel> messages,
  ) async {
    throw const AppException.unimplemented(
      'Chat export is not implemented yet',
    );
  }

  static Future<ImportChatResult> import(String path) async {
    throw const AppException.unimplemented(
      'Chat import is not implemented yet',
    );
  }
}
