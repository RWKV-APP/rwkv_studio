import 'vendor_model.dart';

@pragma("json_id:ae663b59396e364c512f5d5fa3205716")
class PciModel {
  final String iommuGroup;
  final String address;
  final String parentAddress;
  final String driver;
  final String revision;
  final VendorModel? product;
  final VendorModel? programmingInterface;
  final VendorModel? vendor;
  final VendorModel? subclass;
  final VendorModel? subsystem;
  final VendorModel? class_;

  PciModel({
    required this.iommuGroup,
    required this.address,
    required this.parentAddress,
    required this.driver,
    required this.revision,
    this.product,
    this.programmingInterface,
    this.vendor,
    this.subclass,
    this.subsystem,
    this.class_,
  });

  factory PciModel.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return PciModel(
      iommuGroup: json['iommu_group'] ?? '',
      address: json['address'] ?? '',
      parentAddress: json['parent_address'] ?? '',
      driver: json['driver'] ?? '',
      revision: json['revision'] ?? '',
      product: json['product'] != null
          ? VendorModel.fromJson(json['product'])
          : null,
      programmingInterface: json['programming_interface'] != null ? VendorModel
          .fromJson(json['programming_interface']) : null,
      vendor: json['vendor'] != null
          ? VendorModel.fromJson(json['vendor'])
          : null,
      subclass: json['subclass'] != null ? VendorModel.fromJson(
          json['subclass']) : null,
      subsystem: json['subsystem'] != null ? VendorModel.fromJson(
          json['subsystem']) : null,
      class_: json['class'] != null
          ? VendorModel.fromJson(json['class'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['iommu_group'] = iommuGroup;
    data['address'] = address;
    data['parent_address'] = parentAddress;
    data['driver'] = driver;
    data['revision'] = revision;
    data['product'] = product?.toJson();
    data['programming_interface'] = programmingInterface?.toJson();
    data['vendor'] = vendor?.toJson();
    data['subclass'] = subclass?.toJson();
    data['subsystem'] = subsystem?.toJson();
    data['class'] = class_?.toJson();
    return data;
  }

}
