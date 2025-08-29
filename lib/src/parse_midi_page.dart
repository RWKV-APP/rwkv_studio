import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:xmidi/xmidi.dart';

import 'midi_view_state.dart';

class ParseMidiPage extends StatefulWidget {
  const ParseMidiPage({super.key});

  @override
  State<ParseMidiPage> createState() => _ParseMidiPageState();
}

class _ParseMidiPageState extends State<ParseMidiPage> {
  MidiState? midi;
  final player = MidiPlayer();

  MidiDevice? device;
  late final midiCmd = MidiCommand();

  double progress = 0;

  @override
  void initState() {
    super.initState();
    player.midiEventsStream.listen((e) {
      // if (e is! NoteOnEvent || e is! NoteOffEvent) {
      //   return;
      // }
      ByteWriter w = ByteWriter();
      e.writeEvent(w);
      final data = Uint8List.fromList(w.buffer);
      midiCmd.sendData(data, deviceId: device!.id);
      setState(() {
        progress =
            player.currentTimeMs / (midiState.file.getTimeInSeconds() * 1000);
      });
      print("=>$progress");
    });
  }

  @override
  void dispose() {
    super.dispose();
    player.stop();
    midiCmd.dispose();
  }

  void test() async {
    midi = MidiState.create();
    player.load(midi!.file);
    setState(() {});
  }

  void play() async {
    if (device == null) {
      final ds = await midiCmd.devices ?? [];
      device = ds.firstWhere((e) => e.id.contains("Microsoft"));
      try {
        midiCmd.connectToDevice(device!);
        print('connected');
      } catch (_) {
        print('failed!');
        midiCmd.disconnectDevice(device!);
        return;
      }
    } else {
      print('${device!.name} connected');
    }
    await Future.delayed(Duration(seconds: 2));
    print('play...');
    player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parse Midi'),
        actions: [
          IconButton(onPressed: test, icon: Icon(Icons.refresh)),
          IconButton(onPressed: play, icon: Icon(Icons.play_arrow_rounded)),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade300,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse, // 确保鼠标可以滚动
            },
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Stack(
              children: [
                IntrinsicHeight(
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var track in midi?.tracks ?? []) ...[
                          Expanded(
                            child: SizedBox(
                              width: 1500,
                              child: GestureDetector(
                                onTap: () {
                                  midiState.track = midi!.tracks.indexOf(track);
                                  Navigator.pushNamed(context, '/piano');
                                },
                                child: TrackPreview(track: track),
                              ),
                            ),
                          ),
                          Divider(thickness: 1, height: 1, color: Colors.black),
                        ],
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 100 + 1400 * progress,
                  top: 0,
                  width: 1,
                  bottom: 0,
                  child: VerticalDivider(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEvent(NoteOnEvent note, double size) {
    return Positioned(
      width: note.duration! * 10,
      left: note.tick * 5,
      top: note.noteNumber * 1,
      child: Container(
        height: size,
        decoration: BoxDecoration(
          color: Colors.lime,
          // borderRadius: BorderRadius.circular(10),
          // border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text("${note.noteNumber}  ${note.tick}  ${note.duration}"),
      ),
    );
  }
}

class TrackPreview extends StatelessWidget {
  final MidiTrackViewState track;

  final double keyHeight = 14;
  final double widthPerSecond = 10;

  const TrackPreview({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final span = track.max - track.min;
    final scale = 100 / span;
    return Row(
      children: [
        Container(
          width: 100,
          height: 100,
          color: Colors.grey,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${track.track.trackName}\n${track.notes.first.channel}",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              for (var note in track.notes)
                Positioned(
                  left: note.startSeconds * 10,
                  top: 100 - (note.note - track.min) * scale,
                  height: scale,
                  width: note.durationSeconds * 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Text(
                      note.note.toString(),
                      style: const TextStyle(fontSize: 10, height: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class PianoKeyboard extends StatelessWidget {
  final int startNote;
  final int endNote;

  const PianoKeyboard({super.key, this.startNote = 21, this.endNote = 108});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
