import 'package:rwkv_dart/rwkv_dart.dart';

class ModelServiceWrap {
  final ModelService service;
  final String name;

  String get sourceName => name;

  ModelServiceWrap(this.service, {required this.name});

  String get id => service.id;

  String get url => service.url;

  bool get available => service.available;

  List<LoadedModel> get models => service.models;

  Future<void> refresh() => service.refresh();
}
