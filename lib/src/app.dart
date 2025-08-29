import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/parse_midi_page.dart';
import 'package:rwkv_studio/src/midi_device_page.dart';
import 'package:rwkv_studio/src/piano_page.dart';

import 'home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RWKV Studio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        fontFamily: 'Roboto',
        useMaterial3: true,
        fontFamilyFallback: const ['Microsoft YaHei'],
      ),
      home: const HomePage(),
      onGenerateRoute: (settings) {
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
    );
  }
}
