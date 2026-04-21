import 'pci_model.dart';

@pragma("json_id:956fa77e4744af4d2e6c852aeea9f695")
class CardsModel {
  final String address;
  final int index;
  final PciModel? pci;

  CardsModel({
    required this.address,
    required this.index,
    this.pci,
  });

  factory CardsModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return CardsModel(
      address: json['address'] ?? '',
      index: json['index'] ?? 0,
      pci: json['pci'] != null ? PciModel.fromJson(json['pci']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['index'] = index;
    data['pci'] = pci?.toJson();
    return data;
  }

}
