import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_cubit.dart';
import 'package:rwkv_studio/src/cache/hive_manager.dart';
import 'package:rwkv_studio/src/component/toolkit.dart';
import 'package:rwkv_studio/src/component/toolkit/pci_model.dart';
import 'package:rwkv_studio/src/component/toolkit/usage_model.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/common/app_component_update.dart';
import 'package:rwkv_studio/src/models/common/app_info.dart';
import 'package:rwkv_studio/src/models/common/download_task_info.dart';
import 'package:rwkv_studio/src/models/settings/settings_models.dart';
import 'package:rwkv_studio/src/python/interpreter.dart';
import 'package:rwkv_studio/src/repository/common_repository.dart';
import 'package:rwkv_studio/src/repository/repositories.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';

part 'app_state.dart';

part 'component_state.dart';

part 'hardware.dart';

extension Ext on BuildContext {
  AppCubit get app => read<AppCubit>();
}

class AppCubit extends Cubit<AppState> {
  final LocalMachineRepository _localMachineRep;
  final RemoteServiceRepository _remoteServiceRepo;
  final CommonRepository _commonRepo;

  AppCubit(this._localMachineRep, this._remoteServiceRepo, this._commonRepo)
    : super(AppState.initial()) {
    /// Watch LLM provider changes
    _remoteServiceRepo.watchSnapshot().listen((snapshot) {
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
      _localMachineRep.watchHardwareUsageInfo().listen(_onHardwareUsageUpdate);

      await _initAppInfo();
      await _initComponentInfo();
      await _initComponents();
      await _initDownloadTasks();
    }();
  }

  Future updateAppInfo() async {
    final update = await _commonRepo.getAppUpdateInfo();
    if (update != null) {
      emit(state.copyWith(appUpdate: update));
      _refreshUpdateState();
    }
  }

  AppComponent? getComponent(ComponentType type) => state.components[type];

  Future<AppComponent> getRwkvLightning() async {
    final r = state.components[ComponentType.rwkvLightning];
    if (r == null) {
      throw const AppException.notFound(
        'component rwkv-lightning is not found',
      );
    }
    return r;
  }

  void setPane(int pane) {
    emit(state.copyWith(pane: pane));
  }

  Future<List<Python>> detectPythonInterpreters() async {
    final pythons = await _localMachineRep.detectPythonInterpreters().onError(
      (e, st) => <Python>[],
    );
    return pythons;
  }

  Future<Python?> getSelectedPython() async {
    return await _localMachineRep.resolvePythonById(state.selectedPythonId);
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

  Future updateComponent(AppComponent component) {
    return downloadComponent(component);
  }

  Future downloadComponent(AppComponent component) async {
    final info = component.latest;
    logi('app download component: ${info.toJson()}');
    final task = await _commonRepo.download(
      url: info.downloadUrl,
      name: '${info.componentName}_${info.versionName}_${info.versionCode}.zip',
      type: DownloadTaskType.component,
    );
    final tasks = [...state.downloadTasks];
    final index = tasks.indexWhere((e) => e.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
    emit(state.copyWith(downloadTasks: tasks));
  }

  Future installComponentUpdate(AppComponent component) async {
    final t = state.downloadTasks
        .where((e) => e.url == component.latest.downloadUrl)
        .firstOrNull;
    if (t == null) {
      throw const AppException.illegalState(
        'component download info not found',
      );
    }
    await _onComponentDownloaded(t);
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
    final baseNavItems = userType == UserType.developer
        ? NavBarItem.devNavItems()
        : NavBarItem.defaultNavItems();
    final navItems = _syncUpdateNavItems(
      baseNavItems,
      hasAvailableUpdate: state.hasAvailableUpdate,
    );
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
    await _remoteServiceRepo.syncConnections(configs);
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
    final ips = await _localMachineRep.getInterfaceIPAddress();
    logd('interfaces: $ips');
    emit(state.copyWith(ipAddresses: ips));
  }

  Future _initHardwareInfo() async {
    final info = await _localMachineRep.getHardwareInfo();
    final gpus = info.gpu?.cards.map((e) => e.pci).nonNulls.toList() ?? [];

    for (final gpu in gpus) {
      logi('GPU Info: ${gpu.toJson()}');
    }

    if (gpus.isEmpty) {
      logw('No GPU found');
    }

    emit(state.copyWith(hardware: state.hardware.copyWith(gpus: gpus)));
  }

  Future _initAppInfo() async {
    final info = await _commonRepo.loadCurrentAppInfo();
    if (info != null) {
      emit(state.copyWith(appInfo: info));
      logd('app info loaded: ${info.app.versionName} ${info.app.description}');
      _refreshUpdateState();
    }
    await updateAppInfo().logCatchError(msg: 'update app info failed');
  }

  Future _initComponents() async {
    final toolkit = state.components[ComponentType.toolkit];
    if (toolkit != null && !toolkit.missing) {
      logi('start init toolkit');
      await _localMachineRep
          .initToolkit(toolkit.executablePath)
          .logCatchError(msg: 'init hardware tools failed');
      await _initHardwareInfo().logCatchError(
        msg: 'Failed to init hardware info',
      );
      logd('init toolkit success');
    } else {
      logw('component toolkit found');
    }
  }

  Future _initComponentInfo() async {
    if (kIsWeb) return;

    final componentPath = await _commonRepo.getLocalComponentDir();
    final components = <ComponentType, AppComponent>{};

    final current = {
      for (final e in state.appInfo.components) e.componentName: e,
    };
    final latest = {
      for (final e in state.appUpdate.components) e.componentName: e,
    };

    for (final entry in current.entries) {
      final c = entry.value;
      final type = ComponentType.values
          .where((e) => e.name == c.componentName)
          .firstOrNull;
      if (type == null) {
        logw('unknown component type: ${c.componentName}');
        continue;
      }
      final dir = componentPath[type];
      if (dir == null) {
        continue;
      }
      final bin = dir.childFile(c.entryPoint);
      final installed = await bin.exists();
      final latestInfo = latest[c.componentName];
      components[type] = AppComponent(
        dir: dir.path,
        type: type,
        enabled: true,
        missing: !installed,
        external: false,
        bin: c.entryPoint,
        info: c,
        latest: latestInfo ?? c,
      );
      if (latestInfo == null) {
        logw('no latest info for ${c.componentName}');
      }

      logd(
        'load component ${type.name}, '
        'installed=$installed, '
        'path: ${bin.path}',
      );
    }
    emit(state.copyWith(components: components));
  }

  Future _initDownloadTasks() async {
    final ts = await _commonRepo.getDownloadTasks();
    emit(state.copyWith(downloadTasks: ts));
    for (final t in ts) {
      logd('download task restored: ${t.toMap()}');
    }
  }

  Future _onDownloadUpdated(DownloadTaskInfo task) async {
    final ts = [...state.downloadTasks];
    final index = ts.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      ts.add(task);
    } else {
      ts[index] = task;
    }
    emit(state.copyWith(downloadTasks: ts));

    if (task.status.isCompleted) {
      logd('download completed: ${task.name}');
      if (task.type == .component) {
        await _onComponentDownloaded(
          task,
        ).logCatchError(msg: 'component upgrade failed');
      }
      emit(
        state.copyWith(
          downloadTasks: state.downloadTasks
              .where((e) => e.id != task.id)
              .toList(),
        ),
      );
      _commonRepo.deleteTask(task.id);
    }
  }

  Future _onComponentDownloaded(DownloadTaskInfo task) async {
    final type = ComponentType.values.firstWhere(
      (e) => task.name.contains(e.name),
    );
    final comp = state.components[type];
    if (comp == null) {
      loge('download component not found: ${task.name}, ${task.path}');
      return;
    }
    if (comp.external) {
      logw('overwrite external component: ${comp.type.name}');
    } else {
      if (type == .toolkit) {
        Toolkit.kill();
      }

      await _localMachineRep.installComponent(comp, task.path);

      final components = {
        ...state.components,
        type: comp.copyWith(info: comp.latest, missing: false),
      };

      final appInfo = state.appInfo.copyWith(
        components: components.values.map((e) => e.info).toList(),
      );
      _commonRepo.updateLocalAppInfo(appInfo);

      /// check
      _initComponents();

      emit(state.copyWith(components: components, appInfo: appInfo));
    }
  }

  void _refreshUpdateState() {
    final hasAppUpdate = state.hasAppUpdate;
    final navBarItems = _syncUpdateNavItems(
      state.navBarItems,
      hasAvailableUpdate: hasAppUpdate,
    );
    final pane = _remapPane(navBarItems);
    if (state.hasAvailableUpdate == hasAppUpdate &&
        identical(navBarItems, state.navBarItems) &&
        pane == state.pane) {
      return;
    }
    emit(
      state.copyWith(
        hasAvailableUpdate: hasAppUpdate,
        navBarItems: navBarItems,
        pane: pane,
      ),
    );
  }

  List<NavBarItem> _syncUpdateNavItems(
    List<NavBarItem> navBarItems, {
    required bool hasAvailableUpdate,
  }) {
    final updateIndex = navBarItems.indexWhere(
      (item) => item.type == NavBarItemType.updates,
    );
    if (!hasAvailableUpdate) {
      if (updateIndex == -1) {
        return navBarItems;
      }
      return [...navBarItems]..removeAt(updateIndex);
    }

    if (updateIndex != -1) {
      return navBarItems;
    }

    final downloadTaskIndex = navBarItems.indexWhere(
      (item) => item.type == NavBarItemType.downloadTask,
    );
    if (downloadTaskIndex == -1) {
      return navBarItems;
    }

    final next = [...navBarItems];
    next.insert(downloadTaskIndex, NavBarItem(type: NavBarItemType.updates));
    return next;
  }

  void _onHardwareUsageUpdate(HardwareUsageModel info) {
    final hardware = state.hardware.copyWith(
      cpuPercent: info.cpu!.percent,
      memFree: info.memory!.free,
      memTotal: info.memory!.total,
      memProcessPercent: info.process?.memoryPercent,
      cpuProcessPercent: info.process?.cpuPercent,
    );
    emit(state.copyWith(hardware: hardware));
  }

  int _remapPane(List<NavBarItem> navBarItems) {
    if (state.pane < 0) {
      return state.pane;
    }

    final currentItems = state.expandedItems();
    final currentItem = state.pane < currentItems.length
        ? currentItems[state.pane]
        : null;
    final nextItems = navBarItems.flatten(
      (e) => <NavBarItem>[e, ...(e.subitems ?? [])],
    );

    if (currentItem != null) {
      final nextIndex = nextItems.indexWhere((e) => e.type == currentItem.type);
      if (nextIndex != -1) {
        return nextIndex;
      }
    }

    return _clampPane(state.pane, nextItems.length);
  }

  int _clampPane(int pane, int count) {
    if (count <= 0) {
      return -1;
    }
    if (pane < 0) {
      return 0;
    }
    if (pane >= count) {
      return count - 1;
    }
    return pane;
  }
}
