import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/network/http.dart';
import 'package:rwkv_studio/src/widget/desktop_title.dart';
import 'package:rwkv_studio/src/widget/midi_device_panel.dart';
import 'package:rwkv_studio/src/widget/midi_track_preview.dart';
import 'package:rwkv_studio/src/widget/play_progress_line.dart';
import 'package:xmidi/xmidi.dart';

import 'midi/midi_device_manager.dart' show MidiDeviceManager;
import 'midi/midi_player.dart';
import 'midi/midi_view_state.dart';

class ParseMidiPage extends StatefulWidget {
  const ParseMidiPage({super.key});

  @override
  State<ParseMidiPage> createState() => _ParseMidiPageState();
}

class _ParseMidiPageState extends State<ParseMidiPage> {
  final player = MyMidiPlayer();

  double progress = 0;
  int currentTimeMs = 0;
  MidiPlayerStatus playerStatus = MidiPlayerStatus.stop;

  Timer? _refreshTimer;

  List<StreamSubscription> sps = [];

  @override
  void initState() {
    super.initState();

    MidiDeviceManager.init();
    MidiDeviceManager.getDeviceList();
    player.init();
    final sp = player.statusStream.listen((e) {
      print('$e');
      if (e == MidiPlayerStatus.play) {
        player.outputDeviceId = MidiDeviceManager.out?.id ?? '';
        _refreshTimer = Timer.periodic(Duration(milliseconds: 20), (t) {
          setState(() {
            progress = player.currentTimeMs / midiState.totalTimeMills;
            currentTimeMs = player.currentTimeMs;
          });
        });
      } else {
        _refreshTimer?.cancel();
        _refreshTimer = null;
      }
      setState(() {
        playerStatus = e;
        progress = e == MidiPlayerStatus.stop ? 0 : progress;
        currentTimeMs = e == MidiPlayerStatus.stop ? 0 : currentTimeMs;
      });
    });
    sps.add(sp);
  }

  @override
  void dispose() {
    super.dispose();
    player.stop();
    for (final sp in sps) {
      sp.cancel();
    }
    sps.clear();
  }

  void onImportTap() async {
    midiState = MidiState.create();
    player.load(midiState.file!);
    player.player.tempo = midiState.tempo;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade500,
      endDrawer: MidiDevicePanel(),
      appBar: DesktopTitle(title: 'MIDI RWKV (${midiState.fileName})'),
      body: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 2),
            buildActions(),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: buildTrackPreview(),
                ),
              ),
            ),
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
        border: Border.all(color: Colors.black54, width: 1),
      ),
      child: Row(
        children: [
          buildTime(),
          const SizedBox(width: 12),
          Text(
            "${midiState.tempo}BPM",
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
            },
            color: Colors.cyanAccent,
            icon: Icon(Icons.stop),
          ),
          Spacer(),
          Builder(
            builder: (c) => IconButton(
              onPressed: () => Scaffold.of(c).openEndDrawer(),
              icon: Icon(Icons.device_hub, color: Colors.cyanAccent),
            ),
          ),
          IconButton(
            onPressed: onImportTap,
            icon: Icon(Icons.file_open, color: Colors.cyanAccent),
          ),
          IconButton(
            onPressed: () {
              midiState.tracks.add(MidiTrackViewState('New Track'));
              setState(() {});
            },
            color: Colors.cyanAccent,
            icon: Icon(Icons.add),
          ),
          IconButton(
            onPressed: () async {
              final bt = midiState.encode();
              final r = await HTTP.demo.post('/generate', {"prompt": bt});
              print(r);
            },
            color: Colors.cyanAccent,
            icon: Icon(Icons.music_note),
          ),
        ],
      ),
    );
  }

  String formatTime(int timeMs) {
    final min = (timeMs / 1000 / 60).toInt();
    final sec = (timeMs / 1000).toInt() % 60;
    final ms = timeMs.toInt() % 1000;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}:${ms.toString().padLeft(3, '0')}";
  }

  Widget buildTime() {
    return SizedBox(
      width: 90,
      child: Text(
        formatTime(currentTimeMs),
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
                Expanded(
                  child: ColoredBox(
                    color: Colors.grey.shade800,
                    child: CustomPaint(
                      painter: _TrackBg(
                        totalTick: midiState.totalTicks,
                        tickPerBar: midiState.ticksPerBeat,
                        backgroundColor: Colors.black26,
                      ),
                      child: buildTrackList(),
                    ),
                  ),
                ),
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
        border: Border.all(color: Colors.black54, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var track in midiState.tracks) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  midiState.track = midiState.tracks.indexOf(track);
                  Navigator.pushNamed(context, '/piano');
                },
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
            if (track != midiState.tracks.last)
              Divider(height: 1, thickness: 1, color: Colors.black54),
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
                  if (track.name.isNotEmpty)
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

class _TrackBg extends CustomPainter {
  final int totalTick;
  final int tickPerBar;
  final Color backgroundColor;

  late final paint_ = Paint();

  _TrackBg({
    required this.totalTick,
    required this.tickPerBar,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wt = size.width / totalTick;
    final s = wt * (tickPerBar * 4);
    paint_.color = backgroundColor;

    int idx = 0;
    for (var l = 0.0; l < size.width; l += s) {
      if (idx++ % 2 == 0) continue;
      canvas.drawRect(Rect.fromLTWH(l, 0, s, size.height), paint_);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
