class NodeDataType<T> {
  final String id;
  final String name;
  final String description;
  final T defaultValue;

  const NodeDataType({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultValue,
  });

  static const int = _IntDataType();
  static const double = _DoubleDataType();
  static const float = _FloatDataType();
  static const string = _StringDataType();
  static const bool = _BoolDataType();
  static const list = _ListDataType();
  static const map = _MapDataType();
  static const any = _AnyDataType();

  static const void_ = _VoidDataType();
}

class Value {
  final dynamic data;
  final NodeDataType type;
  final dynamic meta;

  Value({required this.data, required this.type, required this.meta});
}

abstract interface class ValueConverter<T> {
  Value convert(Value value);
}

class _IntDataType extends NodeDataType<int> {
  const _IntDataType()
    : super(
        id: 'int',
        name: 'Int',
        description: 'An integer value',
        defaultValue: 0,
      );
}

class _DoubleDataType extends NodeDataType<double> {
  const _DoubleDataType()
    : super(
        id: 'double',
        name: 'Double',
        description: 'A double value',
        defaultValue: 0.0,
      );
}

class _FloatDataType extends NodeDataType<double> {
  const _FloatDataType()
    : super(
        id: 'float',
        name: 'Float',
        description: 'A float value',
        defaultValue: 0.0,
      );
}

class _StringDataType extends NodeDataType<String> {
  const _StringDataType()
    : super(
        id: 'string',
        name: 'String',
        description: 'A string value',
        defaultValue: '',
      );
}

class _BoolDataType extends NodeDataType<bool> {
  const _BoolDataType()
    : super(
        id: 'bool',
        name: 'Bool',
        description: 'A boolean value',
        defaultValue: false,
      );
}

class _ListDataType extends NodeDataType<List<dynamic>> {
  const _ListDataType()
    : super(
        id: 'list',
        name: 'List',
        description: 'A list of values',
        defaultValue: const [],
      );
}

class _MapDataType extends NodeDataType<Map<String, dynamic>> {
  const _MapDataType()
    : super(
        id: 'map',
        name: 'Map',
        description: 'A map of values',
        defaultValue: const {},
      );
}

class _AnyDataType extends NodeDataType<dynamic> {
  const _AnyDataType()
    : super(
        id: 'any',
        name: 'Any',
        description: 'Any value',
        defaultValue: null,
      );
}

class _VoidDataType extends NodeDataType<void> {
  const _VoidDataType()
    : super(
        id: 'void',
        name: 'Void',
        description: 'No value',
        defaultValue: null,
      );
}
