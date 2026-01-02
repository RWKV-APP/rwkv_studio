class NodeContext {
  final Map<String, dynamic> _values = {};
  final String? idempotencyKey;

  NodeContext({this.idempotencyKey});

  void setValue(String name, dynamic value) {
    _values[name] = value;
  }

  dynamic getValue(String name) {
    return _values[name];
  }
}

class SystemEnvironment {
  //
}
