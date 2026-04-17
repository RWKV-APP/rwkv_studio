import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_cubit.dart';
import 'package:rwkv_studio/src/cache/hive_manager.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';
import 'package:rwkv_studio/src/models/common/app_component_update.dart';
import 'package:rwkv_studio/src/models/common/app_info.dart';
import 'package:rwkv_studio/src/models/common/download_task_info.dart';
import 'package:rwkv_studio/src/models/settings/settings_models.dart';
import 'package:rwkv_studio/src/python/interpreter.dart';
import 'package:rwkv_studio/src/repository/common_repository.dart';
import 'package:rwkv_studio/src/repository/repositories.dart';
import 'package:rwkv_studio/src/utils/archive_utils.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';

part 'app_state.dart';

part 'component_state.dart';

extension Ext on BuildContext {
  AppCubit get app => read<AppCubit>();
}

class AppCubit extends Cubit<AppState> {
  final LocalMachineRepository _localMachineRepository;
  final RemoteServiceRepository _remoteServiceRepository;
  final CommonRepository _commonRepo;
  late final StreamSubscription<RemoteServiceSnapshot>
  _remoteServiceSubscription;

  AppCubit(
    this._localMachineRepository,
    this._remoteServiceRepository,
    this._commonRepo,
  ) : super(AppState.initial()) {
    _remoteServiceSubscription = _remoteServiceRepository
        .watchSnapshot()
        .listen((snapshot) {
          emit(state.copyWith(remoteServiceStatuses: snapshot.statuses));
        });
  }

  Future init() async {
    detectPythonInterpreters();

    await AppAssets.init().catchError((e) => loge(e));
    await HiveManager.init().catchError((e) => loge(e));
    _initIPAddress();

    () async {
      _commonRepo.watchDownloadTasks().listen(_onDownloadUpdated);

      await _initAppInfo();
      await _initComponentInfo();
      await _initDownloadTasks();
    }();
  }

  void setPane(int pane) {
    emit(state.copyWith(pane: pane));
  }

  Future<List<Python>> detectPythonInterpreters() async {
    final pythons = await _localMachineRepository
        .detectPythonInterpreters()
        .onError((e, st) => <Python>[]);
    return pythons;
  }

  Future<Python?> getSelectedPython() async {
    return await _localMachineRepository.resolvePythonById(
      state.selectedPythonId,
    );
  }

  void onModelServerSettingChanged(ModelServerSettingsModel setting) async {
    final server = state.rwkvModelService;
    if (setting.enabled) {
      if (server.isRunning()) {
        logd('restarting model server');
        await server.shutdown();
      }
      server.run(host: setting.host, port: setting.port);
    } else {
      server.shutdown();
      logd('shutdown model server');
    }
  }

  void onModelInstanceListChanged(Iterable<ModelInstanceState> models) {
    logd(
      'update rwkv model service model list(${models.length} models): ${models.map((e) => e.info.name).join(',')}',
    );
    state.rwkvModelService.updateInstances([
      for (final m in models)
        HttpServiceModelInstance(
          rwkv: m.rwkv,
          info: ModelBean.fromJson({'id': m.info.name}),
        ),
    ]);
  }

  Future downloadComponent(AppComponent component) async {
    final info = component.latest;
    final task = await _commonRepo.download(
      url: info.downloadUrl,
      name: '${info.componentName}_${info.versionName}_${info.versionCode}.zip',
    );
    emit(state.copyWith(downloadTasks: [...state.downloadTasks, task]));
  }

  Future resumeTask(String id) async {
    await _commonRepo.resumeDownloadTask(id);
  }

  Future pauseTask(String id) async {
    await _commonRepo.pauseDownloadTask(id);
  }

  Future cancelTask(String id) async {
    await _commonRepo.deleteTask(id);
    emit(
      state.copyWith(
        downloadTasks: state.downloadTasks.where((e) => e.id != id).toList(),
      ),
    );
  }

  void onUserTypeChanged(UserType userType) {
    final navItems = userType == UserType.developer
        ? NavBarItem.devNavItems()
        : NavBarItem.defaultNavItems();
    final expand = navItems.flatten(
      (e) => <NavBarItem>[e, ...(e.subitems ?? [])],
    );
    emit(
      state.copyWith(
        navBarItems: navItems,
        pane: state.pane == -1 ? 0 : expand.length - 1,
      ),
    );
  }

  void onPythonSelected({required String id, String? albatrossPath}) {
    emit(state.copyWith(selectedPythonId: id));
  }

  void setShowNavBar(bool show) {
    emit(state.copyWith(showNavBar: show));
  }

  Future updateModelServices(List<RemoteServiceModel> configs) async {
    await _remoteServiceRepository.syncConnections(configs);
  }

  @override
  Future<void> close() async {
    await _remoteServiceSubscription.cancel();
    return super.close();
  }

  Future setFullScreen(bool fullScreen) async {
    if (state.fullScreen == fullScreen) {
      return;
    }
    if (!kIsWeb) {
      if (fullScreen) {
        await Window.enterFullscreen();
        Window.removeToolbar();
      } else {
        await Window.exitFullscreen();
        Window.addToolbar();
      }
    }
    emit(state.copyWith(fullScreen: fullScreen, showNavBar: !fullScreen));
  }

  void toggleFullScreen() async {
    final fullScreen = !state.fullScreen;
    setFullScreen(fullScreen);
  }

  void jump2ModelManage() {
    final i = state.expandedItems().indexWhere(
      (e) => e.type == NavBarItemType.modelManage,
    );
    emit(state.copyWith(pane: i));
  }

  void jump2PythonSettings() {
    final i = state.expandedItems().indexWhere(
      (e) => e.type == NavBarItemType.settings,
    );
    emit(state.copyWith(pane: i));
  }

  void jump2ModelServiceSettings() {
    final i = state.expandedItems().indexWhere(
      (e) => e.type == NavBarItemType.settings,
    );
    emit(state.copyWith(pane: i));
  }

  void _initIPAddress() async {
    final ips = await _localMachineRepository.getInterfaceIPAddress();
    logd('interfaces: $ips');
    emit(state.copyWith(ipAddresses: ips));
  }

  Future _initAppInfo() async {
    final info = await _commonRepo.loadCurrentAppInfo();
    if (info != null) {
      emit(state.copyWith(appInfo: info));
      logd('app info loaded: ${info.app.versionName} ${info.app.description}');
    }
    final update = await _commonRepo.getAppUpdateInfo();
    if (update != null) {
      emit(state.copyWith(appUpdate: update));
    }
  }

  Future _initComponentInfo() async {
    if (kIsWeb) return;

    final current = {
      for (final e in state.appInfo.components) e.componentName: e,
    };
    final latest = {
      for (final e in state.appUpdate.components) e.componentName: e,
    };

    final lightning = await _commonRepo.getRWKVLightningDirectory();
    final componentPath = <ComponentType, Directory>{
      if (lightning != null) ComponentType.rwkvLightning: lightning,
    };
    final cs = state.components.map((c) {
      final dir = componentPath[c.type];
      if (dir != null) {
        return c.copyWith(
          dir: dir.absolute.path,
          external: !dir.isAppPrivate(),
          info: current[c.type.name],
          latest: latest[c.type.name],
        );
      }
      return c;
    }).toList();
    emit(state.copyWith(components: cs));
  }

  Future _initDownloadTasks() async {
    final ts = await _commonRepo.getDownloadTasks();
    emit(state.copyWith(downloadTasks: ts));
    logd('load download tasks: ${ts.length} tasks');
  }

  void _onDownloadUpdated(DownloadTaskInfo task) {
    final ts = state.downloadTasks.map((t) {
      if (t.id == task.id) {
        return task;
      }
      return t;
    }).toList();
    emit(state.copyWith(downloadTasks: ts));

    if (task.status.isCompleted) {
      logd('download completed: ${task.name}');
      if (task.type == .component) {
        _onComponentDownloaded(
          task,
        ).logCatchError(msg: 'component upgrade failed');
        return;
      }
    }
  }

  Future _onComponentDownloaded(DownloadTaskInfo task) async {
    final comp = state.components
        .where((e) => task.name.contains(e.type.name))
        .firstOrNull;
    if (comp == null) {
      loge('download component not found: ${task.name}, ${task.path}');
      return;
    }
    if (comp.external) {
      logw('overwrite external component: ${comp.type.name}');
    } else {
      await ArchiveUtils.extractZip(
        path: task.path,
        outDir: '${comp.dir}_tmp',
      ).last;
      final old = Directory(comp.dir);
      if (old.existsSync()) {
        await old.rename('${comp.dir}_bak');
      }
      await Directory('${comp.dir}_tmp').rename(comp.dir);
      Directory('${comp.dir}_bak').deleteSync(recursive: true);
    }
  }
}
