import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
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
  final StreamSubscription<TaskUpdate>? subscription;

  _DownloadTask({
    required this.info,
    required this.instance,
    this.subscription,
  });

  _DownloadTask copyWith({
    DownloadTaskInfo? info,
    DownloadTask? instance,
    StreamSubscription<TaskUpdate>? subscription,
  }) {
    return _DownloadTask(
      info: info ?? this.info,
      instance: instance ?? this.instance,
      subscription: subscription ?? this.subscription,
    );
  }
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
        .map((b) {
          final json = jsonDecode(b.value);
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
      final restored = task.copyWith(
        status: _restoreTaskStatus(task.status, instance.update),
      );
      _bindTask(restored, instance);
      if (restored.status != task.status) {
        unawaited(_updateTask(restored));
      }
    }
    return _cachedDownloadTasks.values.map((e) => e.info).toList();
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
    final info = await _syncTaskInfo(task.info.id);
    if (info.status.isRunning || info.status.isCompleted) {
      return;
    }
    await _startTask(info);
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
    final taskType = type ?? DownloadTaskType.other;
    await getDownloadTasks();

    final existed = _findDownloadTask(
      url: url,
      path: path,
      name: name,
      type: taskType,
    );
    if (existed != null) {
      final info = await _syncTaskInfo(existed.info.id);
      if (info.status.isRunning || info.status.isCompleted) {
        return info;
      }
      return _startTask(info);
    }

    final info = DownloadTaskInfo(
      id: DateTime.timestamp().millisecondsSinceEpoch.toString(),
      name: name,
      path: path,
      type: taskType,
      url: url,
      status: TaskUpdate.initial(),
    );
    return _startTask(info);
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
    if (!task.instance.update.isCompleted) {
      await task.instance.cancel().logError(
        msg: 'failed to cancel download task',
      );
    }
    await task.subscription?.cancel();
    _cachedDownloadTasks.remove(id);

    await StateCacheBox.delete(id, nameSpace: StateCacheBox.nsDownloadTask);
  }

  _DownloadTask? _findDownloadTask({
    required String url,
    required String path,
    required String name,
    required DownloadTaskType type,
  }) {
    return _cachedDownloadTasks.values
        .where(
          (task) =>
              task.info.url == url &&
              task.info.path == path &&
              task.info.name == name &&
              task.info.type == type,
        )
        .firstOrNull;
  }

  void _bindTask(DownloadTaskInfo info, DownloadTask instance) {
    final old = _cachedDownloadTasks[info.id];
    if (old?.subscription != null) {
      unawaited(old!.subscription!.cancel());
    }
    final subscription = instance.events().listen(
      (e) {
        logi('download task update: $e');
        final task = _cachedDownloadTasks[info.id];
        if (task == null) {
          return;
        }
        final newInfo = task.info.copyWith(status: e);
        _cachedDownloadTasks[info.id] = task.copyWith(info: newInfo);
        _downloadTasksController.add(newInfo);
        unawaited(_updateTask(newInfo));
      },
      onError: (error, stackTrace) {
        loge('download task update error', error, stackTrace);
      },
    );
    _cachedDownloadTasks[info.id] = _DownloadTask(
      info: info,
      instance: instance,
      subscription: subscription,
    );
  }

  TaskUpdate _restoreTaskStatus(TaskUpdate cached, TaskUpdate current) {
    if (!current.isStopped || current.totalSize > 0 || cached.totalSize <= 0) {
      return current;
    }
    return current.copyWith(totalSize: cached.totalSize, speed: 0);
  }

  Future<DownloadTaskInfo> _syncTaskInfo(String id) async {
    final task = _cachedDownloadTasks[id];
    if (task == null) {
      throw const AppException.illegalState('task not found');
    }
    final status = _restoreTaskStatus(task.info.status, task.instance.update);
    if (status == task.info.status) {
      return task.info;
    }
    final info = task.info.copyWith(status: status);
    _cachedDownloadTasks[id] = task.copyWith(info: info);
    await _updateTask(info);
    return info;
  }

  Future<DownloadTaskInfo> _startTask(DownloadTaskInfo info) async {
    final instance = await DownloadTask.create(url: info.url, path: info.path);
    final restored = info.copyWith(
      status: _restoreTaskStatus(info.status, instance.update),
    );
    _bindTask(restored, instance);
    await _updateTask(restored);
    if (restored.status.isRunning || restored.status.isCompleted) {
      return restored;
    }
    await instance.start();
    return _cachedDownloadTasks[info.id]?.info ?? restored;
  }

  Future<AppInfo?> loadCurrentAppInfo() async {
    final json = await FileUtils.readFileJson(AppAssets.appInfoPath);
    if (json == null) {
      loge('failed to load app info');
      return null;
    }
    _cachedAppInfo = AppInfo.fromJson(json);
    logd('app info loaded: $json');
    return _cachedAppInfo;
  }

  Future<AppInfo?> getAppUpdateInfo() async {
    final url = _cachedAppInfo?.updateUrl;
    if (url == null) {
      return null;
    }
    final update = await CommonApi.getAppUpdates(url);
    if (update.updateUrl != url && update.updateUrl.isNotEmpty) {
      final info = _cachedAppInfo!.copyWith(updateUrl: update.updateUrl);
      await updateLocalAppInfo(info);
    }
    return update;
  }

  Future<Map<ComponentType, Directory>> getLocalComponentDir() async {
    final lightning = await getRWKVLightningDirectory();
    final data = appDataDir;
    final toolkit = data.childDirectory("toolkit");
    return {
      ComponentType.rwkvLightning: lightning,
      ComponentType.toolkit: toolkit,
    };
  }

  Future updateLocalAppInfo(AppInfo info) async {
    _cachedAppInfo = info;
    final f = File(AppAssets.appInfoPath);
    final json = jsonEncode(info.toJson());
    f.writeAsString(json).logError(msg: 'failed to update app info');
    logd('local app info updated: $json');
  }

  Future<Directory> getRWKVLightningDirectory() async {
    final home = Platform.environment['RWKV_LIGHTNING_DIR'];
    if (home != null) {
      final dir = Directory(home);
      if (!await dir.exists()) {
        logw(
          'RWKV_LIGHTNING_DIR is set to "$home" but the directory does not exist',
        );
      }
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
