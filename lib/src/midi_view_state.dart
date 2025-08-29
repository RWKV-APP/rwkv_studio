import 'dart:io';

import 'package:xmidi/xmidi.dart';

final noteNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

class MidiNoteViewState {
  int note = 0;
  int duration = 0; // in ticks
  double durationSeconds = 0;
  int start = 0;
  double startSeconds = 0;
  String name = '';
  int channel = 0;
}

class MidiTrackViewState {
  int min = 0;
  int max = 0;
  MidiTrack track;
  List<MidiNoteViewState> notes = [];

  String get name => track.trackName;

  MidiTrackViewState(this.track);

  static MidiTrackViewState fromTrack(MidiTrack track, double ts) {
    var view = MidiTrackViewState(track);

    view.notes = track.events.whereType<NoteOnEvent>().map((e) {
      final oct = e.noteNumber ~/ 12;
      final n = noteNames[e.noteNumber % 12];
      return MidiNoteViewState()
        ..start = e.tick
        ..duration = e.duration!
        ..durationSeconds = e.duration! * ts
        ..startSeconds = e.tick * ts
        ..name = "$n$oct"
        ..channel =  e.channel
        ..note = e.noteNumber;
    }).toList();
    view.notes.sort((a, b) => a.note.compareTo(b.note));
    view.min = view.notes.last.note;
    view.max = view.notes.first.note;
    return view;
  }
}

class MidiState {
  List<MidiTrackViewState> tracks = [];
  MidiFile file;
  int track = 0;

  MidiState(this.file);

  static MidiState create() {
    var file = File(r"C:\Users\dengz\Downloads\test2.mid");
    // Construct a midi reader
    var reader = MidiReader();
    MidiFile midi = reader.parseMidiFromFile(file);

    final ticksPerBeat = midi.header.ticksPerBeat!;
    final bpm = 120;
    final secondsOfTick = (bpm / 60) / ticksPerBeat;

    midiState = MidiState(midi)
      ..tracks = midi.tracks
          .map((e) => MidiTrackViewState.fromTrack(e, secondsOfTick))
          .toList();

    return midiState;
  }
}

late MidiState midiState;
