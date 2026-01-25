import 'dart:async';

import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/network/http.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

abstract class ModelListProvider {
  Future<List<RemoteModelInfo>> getModelList();

  const ModelListProvider();

  factory ModelListProvider.fromService(RwkvServiceClient service) {
    return _ServiceModelListProvider(service);
  }
}

class _ServiceModelListProvider extends ModelListProvider {
  final RwkvServiceClient service;

  _ServiceModelListProvider(this.service);

  @override
  Future<List<RemoteModelInfo>> getModelList() async {
    try {
      final list = await service.getModels();
      final r = list
          .map(
            (e) => RemoteModelInfo.fromMap(e.toJson())
              ..serviceId = service.id
              ..providerName = service.name,
          )
          .toList();
      logd('synced ${r.length} models from ${service.name} (${service.url})');
      return r;
    } on TimeoutException {
      logw('timeout fetching models from ${service.name} (${service.url})');
      return [];
    } catch (_) {
      rethrow;
    }
  }
}

class DefaultModelListProvider extends ModelListProvider {
  final String url;
  final String name;
  final String serviceId;

  DefaultModelListProvider({
    required this.url,
    required this.name,
    required this.serviceId,
  });

  @override
  Future<List<RemoteModelInfo>> getModelList() async {
    try {
      final resp = await HTTP.get(url);
      final list = (resp.data['models'] as Iterable).map((e) {
        return RemoteModelInfo.fromMap(e)
          ..providerName = name
          ..serviceId = serviceId;
      });
      logd('synced ${list.length} models from $name ($url)');
      return list.toList();
    } catch (e, s) {
      loge('failed to fetch models from $name', e, s);
    }
    return [];
  }
}
