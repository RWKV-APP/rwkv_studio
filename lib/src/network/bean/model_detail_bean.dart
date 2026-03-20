import 'modalities_bean.dart';
import 'cost_bean.dart';
import 'limit_bean.dart';

@pragma("json_id:127259674aa1027ce78827ff513d1974")
class ModelDetailBean {
  final String lastUpdated;
  final bool attachment;
  final String releaseDate;
  final bool reasoning;
  final String name;
  final bool toolCall;
  final bool openWeights;
  final String id;
  final String family;
  final ModalitiesBean? modalities;
  final CostBean? cost;
  final LimitBean? limit;

  ModelDetailBean({
    required this.lastUpdated,
    required this.attachment,
    required this.releaseDate,
    required this.reasoning,
    required this.name,
    required this.toolCall,
    required this.openWeights,
    required this.id,
    required this.family,
    this.modalities,
    this.cost,
    this.limit,
  });

  factory ModelDetailBean.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return ModelDetailBean(
      lastUpdated: json['last_updated'] ?? '',
      attachment: json['attachment'] ?? false,
      releaseDate: json['release_date'] ?? '',
      reasoning: json['reasoning'] ?? false,
      name: json['name'] ?? '',
      toolCall: json['tool_call'] ?? false,
      openWeights: json['open_weights'] ?? false,
      id: json['id'] ?? '',
      family: json['family'] ?? '',
      modalities: json['modalities'] != null
          ? ModalitiesBean.fromJson(json['modalities'])
          : null,
      cost: json['cost'] != null ? CostBean.fromJson(json['cost']) : null,
      limit: json['limit'] != null ? LimitBean.fromJson(json['limit']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['last_updated'] = lastUpdated;
    data['attachment'] = attachment;
    data['release_date'] = releaseDate;
    data['reasoning'] = reasoning;
    data['name'] = name;
    data['tool_call'] = toolCall;
    data['open_weights'] = openWeights;
    data['id'] = id;
    data['family'] = family;
    data['modalities'] = modalities?.toJson();
    data['cost'] = cost?.toJson();
    data['limit'] = limit?.toJson();
    return data;
  }
}
