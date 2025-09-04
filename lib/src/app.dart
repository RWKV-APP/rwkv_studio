import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/midi_device_page.dart';
import 'package:rwkv_studio/src/parse_midi_page.dart';
import 'package:rwkv_studio/src/piano_page.dart';
import 'package:window_manager/window_manager.dart';

import 'chat_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        WindowManager.instance.startDragging();
      },
      child: MaterialApp(
        title: 'RWKV Studio',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          fontFamily: 'Bahnschrift',
          useMaterial3: true,
          fontFamilyFallback: const [
            'Bahnschrift',
            'Century Gothic',
            'Microsoft YaHei',
          ],
        ),
        debugShowMaterialGrid: false,
        debugShowCheckedModeBanner: false,
        // showSemanticsDebugger: false,
        home: MainPanel(),
        onGenerateRoute: (settings) {
          if (settings.name == '/chat') {
            return MaterialPageRoute(
              builder: (context) => ChatPage(),
              settings: settings,
            );
          }
          if (settings.name == '/devices') {
            return MaterialPageRoute(
              builder: (context) => MidiDevicePage(),
              settings: settings,
            );
          }
          if (settings.name == '/parse_midi') {
            return MaterialPageRoute(
              builder: (context) => ParseMidiPage(),
              settings: settings,
            );
          }

          if (settings.name == '/piano') {
            return MaterialPageRoute(
              builder: (context) => PianoPage(),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }
}

class MainPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [CloseButton()]),
      body: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, "/chat"),
              child: Text("Chat"),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, "/parse_midi"),
              child: Text("Midi"),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, "/devices"),
              child: Text("Midi Device"),
            ),
          ],
        ),
      ),
    );
  }
}
