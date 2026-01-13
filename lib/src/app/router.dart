import 'package:rwkv_studio/src/ui/chat/chat_page.dart';
import 'package:rwkv_studio/src/ui/common/demo_page.dart';
import 'package:rwkv_studio/src/ui/main/main_page.dart';

class AppRouter {
  static final initialRoute = '/';

  static const String home = '/home';
  static const String chat = '/chat';
  static const String demo = '/demo';

  static final routes = {
    '/': (context) => const MainPage(),
    '/chat': (context) => const ChatPage(),
    '/demo': (context) => const DemoPage(),
  };

  AppRouter._();
}
