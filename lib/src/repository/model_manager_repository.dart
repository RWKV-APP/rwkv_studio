import 'dart:async';

import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/model_provider.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';

class ModelCatalogSnapshot {
  final List<ModelInfo> localModels;
  final List<ModelTag> tags;
  final List<ModelGroup> groups;

  const ModelCatalogSnapshot({
    this.localModels = const [],
    this.tags = const [],
    this.groups = const [],
  });

  factory ModelCatalogSnapshot.empty() {
    return const ModelCatalogSnapshot();
  }
}

class ModelTaskUpdateEvent {
  final String modelId;
  final TaskUpdate update;
  final Object? error;

  const ModelTaskUpdateEvent({
    required this.modelId,
    required this.update,
    this.error,
  });
}

class ModelManagerRepository {
  const ModelManagerRepository();

  Future<void> initialize({
    required String modelDownloadDir,
    required String configProviderUrl,
    DownloadSource? downloadSource,
  }) async {}

  Stream<ModelTaskUpdateEvent> watchTaskUpdates() {
    return const Stream.empty();
  }

  Future<ModelCatalogSnapshot> refreshLocalCatalog() async {
    return ModelCatalogSnapshot.empty();
  }

  Future<List<RemoteModelInfo>> refreshRemoteCatalog(
    Iterable<ModelListProvider> providers,
  ) async {
    return [];
  }

  Future<void> setModelDownloadDir(
    String path, {
    bool migration = false,
  }) async {}

  Future<void> setConfigProviderUrl(String url) async {}

  Future<void> setDownloadSource(DownloadSource source) async {}

  Future<void> download(String id) async {}

  Future<void> pause(String id) async {}

  Future<void> resume(String id) async {}

  Future<void> cancel(String id) async {}

  Future<void> deleteLocalModelFiles(String id) async {}
}
