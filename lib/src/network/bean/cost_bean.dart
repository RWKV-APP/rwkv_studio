@pragma("json_id:d8d097b6b04e18d2f5e0bffbbcfbc0c1")
class CostBean {
  final num output;
  final num input;

  CostBean({
    required this.output,
    required this.input,
  });

  factory CostBean.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return CostBean(
      output: json['output'] ?? 0,
      input: json['input'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['output'] = output;
    data['input'] = input;
    return data;
  }

}
