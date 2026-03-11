import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/models/settings/model_settings_model.dart';

class RemoteServiceConnection {
  final RemoteServiceModel config;
  final ModelService service;

  const RemoteServiceConnection({required this.config, required this.service});
}

class RemoteServiceRepository {
  const RemoteServiceRepository();

  Future<RemoteServiceConnection?> connectService(
    RemoteServiceModel config,
  ) async {
    return null;
  }

  Future<List<RemoteServiceConnection>> connectServices(
    Iterable<RemoteServiceModel> configs,
  ) async {
    return [];
  }

  Future<bool> testConnection(RemoteServiceModel config) async {
    return false;
  }

  Future<void> refreshConnections(
    Iterable<RemoteServiceConnection> connections,
  ) async {}

  Future<List<LoadedModel>> getLoadedModels(
    Iterable<RemoteServiceConnection> connections,
  ) async {
    return [];
  }

  Future<List<RemoteModelInfo>> fetchRemoteModels(
    Iterable<RemoteServiceConnection> connections,
  ) async {
    return [];
  }

  Future<void> disposeConnections(
    Iterable<RemoteServiceConnection> connections,
  ) async {}
}
