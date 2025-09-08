import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:xmidi/xmidi.dart';

class MyMidiPlayer {
  late final player = MidiPlayer();

  String outputDeviceId = '';

  double get progress => player.currentProgress.toDouble();

  int get currentTimeMs => player.currentTimeMs;

  Stream<MidiPlayerStatus> get statusStream => player.statusStream;

  final Set<NoteOffEvent> _independentNoteOffs = {};
  final Map<NoteOnEvent, NoteOffEvent> _playingNotes = {};

  void init() {
    player.midiEventsStream.listen((e) {
      if (e is NoteOnEvent) {
        _playingNotes[e] = e.noteOff!;
      } else if (e is NoteOffEvent) {
        _playingNotes.remove(e.noteOn);
        if (_independentNoteOffs.isNotEmpty &&
            _independentNoteOffs.contains(e)) {
          _independentNoteOffs.remove(e);
          return;
        }
      }
      _writeMidiEvent(e);
    });
  }

  void load(MidiFile file) => player.load(file);

  void pause() {
    player.pause();
    _releaseAllNotes();
  }

  void play() {
    player.play();
  }

  void stop() {
    player.stop();
    _releaseAllNotes();
  }

  void _releaseAllNotes() {
    for (final note in _playingNotes.entries) {
      _writeMidiEvent(note.value);
      _independentNoteOffs.add(note.value);
    }
    print('${_independentNoteOffs.length} notes released');
  }

  void _writeMidiEvent(MidiEvent e) {
    ByteWriter w = ByteWriter();
    e.writeEvent(w);
    final data = Uint8List.fromList(w.buffer);
    MidiCommand().sendData(data, deviceId: outputDeviceId);
  }
}
