import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/midi/midi_view_state.dart';
import 'package:rwkv_studio/src/widget/track_editor_view.dart';

class PianoPage extends StatefulWidget {
  const PianoPage({super.key});

  @override
  State<PianoPage> createState() => _PianoPageState();
}

class _PianoPageState extends State<PianoPage> {
  late MidiTrackViewState track;

  @override
  void initState() {
    super.initState();
    track = midiState.tracks[midiState.track];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(track.name)),
      body: Container(child: TrackEditorView(notes: track.notes)),
    );
  }
}
