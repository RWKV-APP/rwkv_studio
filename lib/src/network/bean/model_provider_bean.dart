import 'package:rwkv_studio/src/network/bean/model_detail_bean.dart';

@pragma("json_id:fe8744afc01949ab658d97bd4289c4d1")
class ModelProviderBean {
  final String name;
  final String doc;
  final String npm;
  final String id;
  final String api;
  final Map<String, ModelDetailBean> models;
  final List<String> env;

  ModelProviderBean({
    required this.name,
    required this.doc,
    required this.npm,
    required this.id,
    required this.api,
    required this.models,
    required this.env,
  });

  factory ModelProviderBean.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    final models = json['models'] ?? {};
    return ModelProviderBean(
      name: json['name'] ?? '',
      doc: json['doc'] ?? '',
      npm: json['npm'] ?? '',
      id: json['id'] ?? '',
      api: json['api'] ?? '',
      models: {
        for (final entry in models.entries)
          entry.key: ModelDetailBean.fromJson(entry.value),
      },
      env: (json['env'] as Iterable?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['doc'] = doc;
    data['npm'] = npm;
    data['id'] = id;
    data['api'] = api;
    data['models'] = {
      for (final entry in models.entries) entry.key: entry.value.toJson(),
    };
    data['env'] = env;
    return data;
  }
}
