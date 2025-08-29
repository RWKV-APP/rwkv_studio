import 'package:flutter_midi_command/flutter_midi_command.dart';

class MidiDeviceManager {
  static final midiCmd = MidiCommand();
  static final List<MidiDevice> devices = [];

  static MidiDevice? out;
  static MidiDevice? in_;

  static void init() {
    midiCmd.onMidiSetupChanged?.listen((event) {
      print("onMidiSetupChanged: $event");
    });
    midiCmd.onMidiDataReceived?.listen((event) {
      print("onMidiDataReceived: ${event.data}, ${out?.name}");
      midiCmd.sendData(
        event.data,
        deviceId: out?.id,
        timestamp: event.timestamp,
      );
    });
    midiCmd.onBluetoothStateChanged.listen((e) {
      print("onBluetoothStateChanged: ${e}");
    });
  }

  static Future<List<MidiDevice>> getDeviceList() async {
    devices.clear();
    devices.addAll((await midiCmd.devices) ?? []);

    try {
      await connectDefaultOutputDevice();
    } catch (e) {
      print(e);
    }

    return devices;
  }

  static Future toggleDevice(MidiDevice device) async {
    if (device.connected) {
      disconnect(device);
    } else {
      await connect(device);
    }
    await getDeviceList();
  }

  static Future connect(MidiDevice device) async {
    if (device.connected) {
      return;
    }
    await midiCmd.connectToDevice(device);
  }

  static void disconnect(MidiDevice device) {
    midiCmd.disconnectDevice(device);
  }

  static Future connectDefaultOutputDevice() async {
    for (final d in devices) {
      if (d.outputPorts.isNotEmpty && !d.connected) {
        if (d.name == "Microsoft GS Wavetable Synth") {
          midiCmd.connectToDevice(d);
          break;
        }
      }
    }
  }
}
