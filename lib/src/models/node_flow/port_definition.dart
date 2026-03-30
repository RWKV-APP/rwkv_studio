class PortDefinition {
  final String name;
  final bool multiConnections;
  final bool isInput;

  static const controlIn = PortDefinition(
    name: 'IN',
    multiConnections: true,
    isInput: true,
  );
  static const controlOut = PortDefinition(
    name: 'OUT',
    multiConnections: false,
    isInput: false,
  );

  const PortDefinition({
    required this.name,
    this.multiConnections = false,
    required this.isInput,
  });

  factory PortDefinition.input({
    required String name,
    bool multiConnections = false,
  }) {
    return PortDefinition(
      name: name,
      multiConnections: multiConnections,
      isInput: true,
    );
  }

  factory PortDefinition.output({
    required String name,
    bool multiConnections = true,
  }) {
    return PortDefinition(
      name: name,
      multiConnections: multiConnections,
      isInput: false,
    );
  }
}
