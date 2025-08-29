import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:rwkv_studio/src/midi_device_manager.dart';

class MidiDevicePage extends StatefulWidget {
  const MidiDevicePage({super.key});

  @override
  State<MidiDevicePage> createState() => _MidiDevicePageState();
}

class _MidiDevicePageState extends State<MidiDevicePage> {
  final List<MidiDevice> devices = [];

  @override
  void initState() {
    super.initState();
    getDevices();
  }

  void play() async {
    Navigator.of(context).pushNamed('/parse_midi');
  }

  void getDevices() async {
    final ds = await MidiDeviceManager.getDeviceList();
    setState(() {
      devices.clear();
      devices.addAll(ds);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Midi Device')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton(onPressed: getDevices, child: Text("Get Devices")),
              TextButton(onPressed: () {}, child: Text("Scan")),
              TextButton(onPressed: () {}, child: Text("Ble")),
              TextButton(onPressed: () {}, child: Text("Stop Scan")),
              TextButton(onPressed: play, child: Text("Midi-File")),
            ],
          ),
          for (final d in devices)
            ListTile(
              onTap: () async {
                await MidiDeviceManager.toggleDevice(d);
                getDevices();
              },
              title: Row(
                children: [
                  Text(
                    "${d.name}",
                    style: TextStyle(
                      color: d.connected ? Colors.green : Colors.black,
                    ),
                  ),
                ],
              ),
              subtitle: Text("id: ${d.id}, type: ${d.type}"),
              trailing: Text(d.connected ? "Connected" : ""),
            ),
        ],
      ),
    );
  }
}
