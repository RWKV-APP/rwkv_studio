import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/component/toolkit.dart';
import 'package:rwkv_studio/src/component/toolkit/hardware_model.dart';
import 'package:rwkv_studio/src/component/toolkit/usage_model.dart';
import 'package:rwkv_studio/src/python/interpreter.dart';
import 'package:rwkv_studio/src/utils/archive_utils.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';

class LocalMachineRepository {
  List<Python> _pythons = [];

  LocalMachineRepository();

  Future initToolkit(String bin) async {
    await Toolkit.init(bin);
  }

  Stream<HardwareUsageModel> watchHardwareUsageInfo() async* {
    yield* Toolkit.watchHardwareUsage(pid: pid, interval: 2);
  }

  Future installComponent(AppComponent comp, String zip) async {
    final compDirPath = comp.dir;
    final tmpPath = '${compDirPath}_tmp';
    final bakPath = '${compDirPath}_bak';
    logd('start install component: ${comp.type.name}, $zip => ${comp.dir}');

    if (comp.type == .toolkit) {
      await Toolkit.kill();
    }

    final tmp = Directory(tmpPath);
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }

    await ArchiveUtils.extractZip(path: zip, outDir: tmpPath).last;
    final old = Directory(compDirPath);
    final isUpgrade = await old.exists();
    final bak = Directory(bakPath);
    if (isUpgrade) {
      if (await bak.exists()) {
        await bak.delete(recursive: true);
      }
      await old.rename(bakPath);
    }
    try {
      await tmp.rename(compDirPath);
    } catch (e, st) {
      if (isUpgrade) {
        await _rollbackComponentUpgrade(
          compDirPath: compDirPath,
          bakPath: bakPath,
          tmpPath: tmpPath,
        );
      }
      loge('install component failed: ${comp.type.name}', e, st);
      rethrow;
    }
    if (isUpgrade) {
      await bak
          .delete(recursive: true)
          .logCatchError(msg: 'remove component backup failed');
    }
    logd('component installed: ${comp.type.name}');

    await File(zip).delete().logCatchError(msg: 'remove component zip failed');

    if (comp.type == .toolkit) {
      await Toolkit.init(pathJoin(compDirPath, comp.bin));
    }
  }

  Future<void> _rollbackComponentUpgrade({
    required String compDirPath,
    required String bakPath,
    required String tmpPath,
  }) async {
    final compDir = Directory(compDirPath);
    final bak = Directory(bakPath);
    final tmp = Directory(tmpPath);

    if (await compDir.exists()) {
      await compDir
          .delete(recursive: true)
          .logCatchError(
            msg: 'remove failed component dir before rollback failed',
          );
    }
    if (await bak.exists()) {
      await bak
          .rename(compDirPath)
          .logCatchError(msg: 'restore component backup failed');
    }
    if (await tmp.exists()) {
      await tmp
          .delete(recursive: true)
          .logCatchError(msg: 'remove component tmp after rollback failed');
    }
  }

  Future<HardwareModel> getHardwareInfo() async {
    return await Toolkit.getHardwareInfo();
  }

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
    _pythons = [
      for (final item in python) Python.fromPath(item),
      for (final item in conda) Python.fromCondaEnv(item),
    ];
    return _pythons;
  }

  Future<Python?> resolvePythonById(String id) async {
    if (id.isEmpty) {
      return null;
    }
    if (_pythons.isEmpty) {
      await detectPythonInterpreters();
    }
    for (final python in _pythons) {
      if (python.id == id) {
        return python;
      }
    }
    return null;
  }
}
