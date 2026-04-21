import 'cards_model.dart';

@pragma("json_id:887b27f77c9fd12a73b51011e1241c6b")
class GpuModel {
  final List<CardsModel> cards;

  GpuModel({
    required this.cards,
  });

  factory GpuModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return GpuModel(
      cards: (json['cards'] as Iterable?)
          ?.map((e) => CardsModel.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cards'] = cards.map((e) => e.toJson()).toList();
    return data;
  }

}
