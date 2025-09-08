import 'dart:convert';

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
  String name = '';
  int channel = 0;
  List<MidiNoteViewState> notes = [];

  MidiTrackViewState(this.name);

  static MidiTrackViewState fromTrack(MidiTrack track, double tickInSec) {
    var view = MidiTrackViewState(track.trackName);

    view.notes = track.events.whereType<NoteOnEvent>().map((e) {
      final oct = e.noteNumber ~/ 12;
      final n = noteNames[e.noteNumber % 12];
      view.channel = e.channel;
      return MidiNoteViewState()
        ..start = e.tick
        ..duration = e.duration!
        ..durationSeconds = e.duration! / tickInSec
        ..startSeconds = e.tick / tickInSec
        ..name = "$n$oct"
        ..channel = e.channel
        ..note = e.noteNumber;
    }).toList();
    if (view.notes.isNotEmpty) {
      view.notes.sort((a, b) => a.note.compareTo(b.note));
      view.min = view.notes.last.note;
      view.max = view.notes.first.note;
    }

    final ns = track.events.where(
      (e) => e is! NoteOnEvent && e is! NoteOffEvent,
    );
    print('===${view.name} ${view.channel}===');
    for (final event in ns) {
      if (event is ControllerEvent) {
        // print('CC ${note.controllerType} ${note.value}');
      } else if (event is ProgramChangeMidiEvent) {
        // print('PC ${note.programNumber} ${note.channel}');
      } else if (event is MarkerEvent) {
        print('Marker: ${event.text}');
      } else if (event is PortPrefixEvent) {
        print('PortPrefix: ${event.port}');
      } else if (event is KeySignatureEvent) {
        print('KeySignature: ${event.key}, ${event.scale}');
      } else {
        print('>${event}');
      }
    }
    if (view.name.isEmpty) {
      view.name = "Track ${view.channel}";
    }
    return view;
  }
}

class MidiState {
  List<MidiTrackViewState> tracks = [];
  MidiFile? file;
  int track = 0;
  double totalTimeMills = 0;
  int totalTicks = 0;
  int ticksPerBeat = 0;
  int tempo = 120;
  String fileName = '';
  String ts = '4/4';

  MidiState(this.file);

  String encode() {
    final wrt = MidiWriter();
    final bf = wrt.writeMidiToBuffer(file!);
    return base64Encode(bf);
  }

  static MidiState create() {
    var path = r"C:/Users/dengz/Downloads/test.mid";
    final midi = MidiFile.readFromFile(path);

    final track1 = midi.tracks.firstOrNull?.events;
    final tempos = track1?.whereType<SetTempoEvent>() ?? [];
    final mspb = tempos.firstOrNull?.microsecondsPerBeat ?? 500000;
    final tempo = (60 / (mspb / 1000 / 1000)).round();
    print('tempo:$tempo');

    final tss = track1?.whereType<TimeSignatureEvent>() ?? [];
    final ts = tss.firstOrNull;
    final n = ts?.numerator ?? 4;
    final d = ts?.denominator ?? 4;
    print('time signature: $n/$d');

    final ticksPerBeat = midi.header.ticksPerBeat!;
    final secOfTick = ticksPerBeat * tempo / 60;

    midiState = MidiState(midi)
      ..tempo = tempo
      ..ts = '$n/$d'
      ..totalTimeMills = midi.getTimeInSeconds() * 1000
      ..tracks = midi.tracks
          .map((e) => MidiTrackViewState.fromTrack(e, secOfTick))
          .toList();

    print('tracks:${midiState.tracks.length}, ${midi.tracks.length}');

    midiState.totalTicks = midi.getFileDurationTicks();
    midiState.ticksPerBeat = ticksPerBeat;

    midiState.tracks.add(MidiTrackViewState(''));
    midiState.tracks.add(MidiTrackViewState(''));
    midiState.tracks.add(MidiTrackViewState(''));
    midiState.tracks.add(MidiTrackViewState(''));

    midiState.fileName = path.split('/').last;

    return midiState;
  }

  static void save() {}
}

MidiState midiState = MidiState(null);
