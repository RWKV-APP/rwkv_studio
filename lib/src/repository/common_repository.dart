import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/cache/state_cache_box.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/common/app_info.dart';
import 'package:rwkv_studio/src/models/common/download_task_info.dart';
import 'package:rwkv_studio/src/network/common_api.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/file_util.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';

class _DownloadTask {
  final DownloadTaskInfo info;
  final DownloadTask instance;

  _DownloadTask({required this.info, required this.instance});
}

class CommonRepository {
  AppInfo? _cachedAppInfo;
  final Map<String, _DownloadTask> _cachedDownloadTasks = {};

  final StreamController<DownloadTaskInfo> _downloadTasksController =
      StreamController.broadcast();

  CommonRepository();

  Stream<DownloadTaskInfo> watchDownloadTasks() {
    return _downloadTasksController.stream;
  }

  Future<List<DownloadTaskInfo>> getDownloadTasks() async {
    if (_cachedDownloadTasks.isNotEmpty) {
      return _cachedDownloadTasks.values.map((e) => e.info).toList();
    }

    final box = await StateCacheBox.getAll(
      nameSpace: StateCacheBox.nsDownloadTask,
    );

    final tasks = box
        .map((e) {
          final json = jsonDecode(e.value);
          try {
            return DownloadTaskInfo.fromMap(json);
          } catch (e) {
            loge(e);
            return null;
          }
        })
        .nonNulls
        .toList();

    for (var task in tasks) {
      final instance = await DownloadTask.create(
        url: task.url,
        path: task.path,
      );
      _cachedDownloadTasks[task.id] = _DownloadTask(
        info: task,
        instance: instance,
      );
    }
    return tasks;
  }

  Future pauseDownloadTask(String id) async {
    final task = _cachedDownloadTasks[id];
    if (task == null) {
      throw const AppException.illegalState('task not found');
    }
    await task.instance.stop();
  }

  Future resumeDownloadTask(String id) async {
    final task = _cachedDownloadTasks[id];
    if (task == null) {
      throw const AppException.illegalState('task not found');
    }
    await task.instance.start();
  }

  Future<DownloadTaskInfo> download({
    required String url,
    required String name,
    DownloadTaskType? type,
    String? path,
  }) async {
    if (path == null) {
      final f = appDataDir.childFile(name);
      path = f.absolute.path;
    }
    final info = DownloadTaskInfo(
      id: DateTime.timestamp().millisecondsSinceEpoch.toString(),
      name: name,
      path: path,
      type: type ?? DownloadTaskType.other,
      url: url,
      status: TaskUpdate.initial(),
    );

    final instance = await DownloadTask.create(url: info.url, path: info.path);
    _cachedDownloadTasks[info.id] = _DownloadTask(
      info: info,
      instance: instance,
    );
    instance.events().listen((e) {
      logi('download task update: $e');
      final task = _cachedDownloadTasks[info.id];
      if (task == null) {
        return;
      }
      final newInfo = task.info.copyWith(status: e);
      _cachedDownloadTasks[info.id] = _DownloadTask(
        info: newInfo,
        instance: task.instance,
      );
      _downloadTasksController.add(newInfo);
      _updateTask(newInfo);
    });
    await instance.start();
    return info;
  }

  Future _updateTask(DownloadTaskInfo task) async {
    final json = jsonEncode(task.toMap());
    await StateCacheBox.put(
      task.id,
      json,
      nameSpace: StateCacheBox.nsDownloadTask,
    );
  }

  Future deleteTask(String id) async {
    final task = _cachedDownloadTasks[id];
    if (task == null) {
      return;
    }
    await task.instance.stop().logError(msg: 'failed to stop download task');
    _cachedDownloadTasks.remove(id);

    await StateCacheBox.delete(id, nameSpace: StateCacheBox.nsDownloadTask);
  }

  Future<AppInfo?> loadCurrentAppInfo() async {
    final json = await FileUtils.readFileJson(AppAssets.appInfoPath);
    if (json == null) {
      loge('failed to load app info');
      return null;
    }
    _cachedAppInfo = AppInfo.fromJson(json);
    return _cachedAppInfo;
  }

  Future<AppInfo?> getAppUpdateInfo() async {
    final url = _cachedAppInfo?.updateUrl;
    if (url == null) {
      return null;
    }
    final a = await CommonApi.getAppUpdates(url);
    if (a.updateUrl != url) {
      final f = File(AppAssets.appInfoPath);
      final n = _cachedAppInfo!.copyWith(updateUrl: a.updateUrl);
      _cachedAppInfo = n;
      final json = jsonEncode(n.toJson());
      f.writeAsString(json).logError(msg: 'failed to update app info');
    }
    return a;
  }

  Future<Directory?> getRWKVLightningDirectory() async {
    final home = Platform.environment['RWKV_LIGHTNING_DIR'];
    if (home != null) {
      final dir = Directory(home);
      if (!await dir.exists()) {
        logw(
          'RWKV_LIGHTNING_DIR is set to "$home" but the directory does not exist',
        );
      }
      return dir;
    }
    final cached = await _getCachedRWKVLightningDirectory();
    if (cached != null) {
      return cached;
    }
    final data = appDataDir;
    return data.childDirectory("rwkv_lightning");
  }

  Future cacheRWKVLightningDirectory(Directory dir) async {
    await StateCacheBox.put('rwkv_lightning_dir', dir.absolute.path);
  }

  Future<Directory?> _getCachedRWKVLightningDirectory() async {
    final cachedPath = await StateCacheBox.get('rwkv_lightning_dir');
    if (cachedPath != null) {
      final cachedDir = Directory(cachedPath.value);
      if (await cachedDir.exists()) {
        return cachedDir;
      }
    }
    return null;
  }
}
