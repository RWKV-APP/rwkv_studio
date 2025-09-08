import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:rwkv_studio/src/midi/midi_device_manager.dart';

class MidiDevicePanel extends StatefulWidget {
  const MidiDevicePanel({super.key});

  @override
  State<MidiDevicePanel> createState() => _MidiDevicePanelState();
}

class _MidiDevicePanelState extends State<MidiDevicePanel> {
  final List<MidiDevice> input = [];
  final List<MidiDevice> output = [];

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
      input.clear();
      output.clear();
      input.addAll(ds.where((e) => e.inputPorts.isNotEmpty));
      output.addAll(ds.where((e) => e.outputPorts.isNotEmpty));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 450,
      height: double.infinity,
      child: Material(
        color: Colors.grey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 16),
                Text('Midi Device', style: TextStyle(fontSize: 22)),
                Spacer(),
                TextButton(onPressed: getDevices, child: Text("Refresh")),
                TextButton(onPressed: () {}, child: Text("Scan BLE")),
                TextButton(onPressed: () {}, child: Text("Stop Scan")),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.grey.shade600,
              child: Text('Input'),
            ),
            if (input.isEmpty)
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('No input devices'),
              ),
            ...buildList(input),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.grey.shade600,
              child: Text('Output'),
            ),
            ...buildList(output),
            if (output.isEmpty)
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('No output devices'),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildList(List<MidiDevice> devices) {
    return [
      for (final d in devices)
        ListTile(
          onTap: () async {
            await MidiDeviceManager.toggleDevice(d);
            getDevices();
          },
          title: Row(
            children: [
              Text(
                d.name,
                style: TextStyle(
                  color: d.connected ? Colors.cyanAccent.shade400 : Colors.black,
                ),
              ),
            ],
          ),
          subtitle: Text("id: ${d.id}, type: ${d.type}"),
          trailing: Text(d.connected ? "Connected" : ""),
        ),
    ];
  }
}
