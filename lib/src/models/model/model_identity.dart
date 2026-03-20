import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';

extension ModelIdentityExtension on ModelInfo {
  ModelIdentity getIdentity() => ModelIdentity.fromModelInfo(this);
}

class ModelIdentity extends Equatable {
  final String provider;
  final String name;
  final String id;

  @override
  List<Object?> get props => [provider, name, id];

  const ModelIdentity._({
    required this.provider,
    required this.name,
    required this.id,
  });

  factory ModelIdentity.fromModelInfo(ModelInfo info) {
    return ModelIdentity._(
      provider: info.providerName,
      name: info.name,
      id: info.id,
    );
  }

  factory ModelIdentity.fromMap(dynamic map) {
    return ModelIdentity._(
      provider: map['provider'] ?? '',
      name: map['name'] ?? '',
      id: map['id'] ?? '',
    );
  }

  Map toMap() {
    return {'provider': provider, 'name': name, 'id': id};
  }
}
