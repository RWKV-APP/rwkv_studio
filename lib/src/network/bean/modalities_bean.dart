@pragma("json_id:5b7186accdbc2f0cca4c9d90c795e0ef")
class ModalitiesBean {
  final List<String> output;
  final List<String> input;

  ModalitiesBean({
    required this.output,
    required this.input,
  });

  factory ModalitiesBean.fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return ModalitiesBean(
      output: (json['output'] as Iterable?)?.map((e) => e as String).toList() ??
          [],
      input: (json['input'] as Iterable?)?.map((e) => e as String).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['output'] = output;
    data['input'] = input;
    return data;
  }

}
