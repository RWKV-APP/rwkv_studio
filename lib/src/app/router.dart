import 'package:rwkv_studio/src/ui/chat/chat_page.dart';
import 'package:rwkv_studio/src/ui/main/main_page.dart';

class AppRouter {
  static final initialRoute = '/';

  static const String home = '/home';
  static const String chat = '/chat';

  static final routes = {
    '/': (context) => const MainPage(),
    '/chat': (context) => const ChatPage(),
  };

  AppRouter._();
}
