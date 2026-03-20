@pragma("json_id:6c4f9e84b5eea98b9b1d88c2c4c0749c")
class LimitBean {
  final int output;
  final int context;

  LimitBean({
    required this.output,
    required this.context,
  });

  factory LimitBean.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return LimitBean(
      output: json['output'] ?? 0,
      context: json['context'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['output'] = output;
    data['context'] = context;
    return data;
  }

}
