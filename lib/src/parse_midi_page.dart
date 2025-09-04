import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:rwkv_studio/src/widget/midi_track_preview.dart';
import 'package:rwkv_studio/src/widget/play_progress_line.dart';
import 'package:xmidi/xmidi.dart';

import 'midi/midi_device_manager.dart' show MidiDeviceManager;
import 'midi/midi_view_state.dart';

class ParseMidiPage extends StatefulWidget {
  const ParseMidiPage({super.key});

  @override
  State<ParseMidiPage> createState() => _ParseMidiPageState();
}

class _ParseMidiPageState extends State<ParseMidiPage> {
  final player = MidiPlayer();

  late final midiCmd = MidiCommand();

  double progress = 0;
  MidiPlayerStatus playerStatus = MidiPlayerStatus.stop;

  @override
  void initState() {
    super.initState();

    MidiDeviceManager.init();
    MidiDeviceManager.getDeviceList();
    player.statusStream.listen((e) {
      print('$e');
      setState(() {
        playerStatus = e;
      });
    });
    player.midiEventsStream.listen((e) {
      // if (e is! NoteOnEvent || e is! NoteOffEvent) {
      //   return;
      // }
      ByteWriter w = ByteWriter();
      e.writeEvent(w);
      final data = Uint8List.fromList(w.buffer);
      midiCmd.sendData(data, deviceId: MidiDeviceManager.out!.id);
      setState(() {
        progress = player.currentTimeMs / (midiState.totalTimeMills);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    player.stop();
    midiCmd.dispose();
  }

  void onImportTap() async {
    midiState = MidiState.create();
    player.load(midiState.file!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade500,
      body: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.white60,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Text('MIDI-RWKV', style: TextStyle(color: Colors.black87)),
                    Spacer(),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            buildActions(),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse, // 确保鼠标可以滚动
                  },
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: buildTrackPreview(),
                ),
              ),
            ),
            // Center(
            //   child: Text(
            //     'MIDI-RWKV',
            //     style: TextStyle(
            //       fontWeight: FontWeight.bold,
            //       fontSize: 20,
            //       color: Colors.cyanAccent.shade200,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget buildActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26, width: 1),
      ),
      child: Row(
        children: [
          buildTime(),
          const SizedBox(width: 12),
          Text(
            "120BPM",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              if (playerStatus == MidiPlayerStatus.play) {
                player.pause();
              } else {
                player.play();
              }
            },
            color: Colors.cyanAccent,
            icon: Icon(
              playerStatus == MidiPlayerStatus.play
                  ? Icons.pause
                  : Icons.play_arrow_rounded,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () {
              player.stop();
              setState(() {
                progress = 0;
              });
            },
            color: Colors.cyanAccent,
            icon: Icon(Icons.stop),
          ),
          Spacer(),
          IconButton(
            onPressed: onImportTap,
            icon: Icon(Icons.file_open, color: Colors.cyanAccent),
          ),
          IconButton(
            onPressed: () {
              //
            },
            color: Colors.cyanAccent,
            icon: Icon(Icons.add),
          ),
          IconButton(
            onPressed: () {
              midiState.tracks.add(MidiTrackViewState('New Track'));
              setState(() {});
            },
            color: Colors.cyanAccent,
            icon: Icon(Icons.music_note),
          ),
        ],
      ),
    );
  }

  String formatTime(double time) {
    final min = (time / 1000 / 60).toInt();
    final sec = (time / 1000).toInt() % 60;
    final ms = time.toInt() % 1000;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}:${ms.toString().padLeft(3, '0')}";
  }

  Widget buildTime() {
    final p = (midiState.totalTimeMills) * progress;
    return SizedBox(
      width: 80,
      child: Text(
        formatTime(p),
        style: TextStyle(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget buildTrackPreview() {
    if (midiState.tracks.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        color: Colors.grey.shade500,
        child: Text('Empty', style: TextStyle(color: Colors.grey.shade200)),
      );
    }
    final height = 55.0 * (midiState.tracks.length);
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: 0,
            right: 0,
            height: height,
            left: 0,
            child: Row(
              children: [
                SizedBox(width: 100, child: buildTrackNameList()),
                Expanded(child: buildTrackList()),
              ],
            ),
          ),
          if (progress != 0)
            Positioned(
              left: 100,
              bottom: 0,
              height: height,
              right: 0,
              child: IgnorePointer(child: ProgressLine(progress: progress)),
            ),
        ],
      ),
    );
  }

  Widget buildTrackList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var track in midiState.tracks) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  print('object');
                  midiState.track = midiState.tracks.indexOf(track);
                  Navigator.pushNamed(context, '/piano');
                },
                child: Container(
                  color: Colors.grey.shade800,
                  child: MidiTrackPreview(
                    notes: track.notes
                        .map(
                          (e) => MidiNote(
                            note: e.note,
                            start: e.startSeconds,
                            duration: e.durationSeconds,
                          ),
                        )
                        .toList(),
                    trackDuration: midiState.totalTimeMills / 1000,
                  ),
                ),
              ),
            ),
            if (track != midiState.tracks.last)
              Divider(height: 1.5, thickness: 1.5, color: Colors.black),
          ],
        ],
      ),
    );
  }

  Widget buildTrackNameList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        for (final track in midiState.tracks)
          Expanded(
            child: Container(
              color: Colors.grey.shade600,
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(vertical: 1, horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${track.name}\n channel:${track.notes.firstOrNull?.channel}",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: Colors.grey.shade200,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
