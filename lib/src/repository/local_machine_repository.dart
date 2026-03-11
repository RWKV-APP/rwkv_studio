import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:rwkv_studio/src/python/interpreter.dart';

class LocalMachineRepository {
  const LocalMachineRepository();

  Future<List<String>> getInterfaceIPAddress() async {
    if (kIsWeb) {
      return [];
    }
    final ips = <String>{};
    const lanIP = {'192', '172', '10'};
    for (final item in await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    )) {
      for (final address in item.addresses) {
        if (address.address == '127.0.0.1' ||
            address.address == '0.0.0.0' ||
            address.isMulticast ||
            address.address.isEmpty) {
          continue;
        }
        if (!lanIP.contains(address.address.split('.').first)) {
          continue;
        }
        ips.add(address.address);
      }
    }
    return ips.toList();
  }

  Future<List<Python>> detectPythonInterpreters() async {
    if (kIsWeb) {
      return [];
    }
    final python = await Python.findPythons().onError((e, st) => <String>[]);
    final conda = await Python.detectCondaEnv().onError(
      (e, st) => <CondaEnv>[],
    );
    return [
      for (final item in python) Python.fromPath(item),
      for (final item in conda) Python.fromCondaEnv(item),
    ];
  }

  Future<Python?> resolvePythonById(String id) async {
    if (id.isEmpty) {
      return null;
    }
    final pythons = await detectPythonInterpreters();
    for (final python in pythons) {
      if (python.id == id) {
        return python;
      }
    }
    return null;
  }
}
