class NodeFlowRepository {
  const NodeFlowRepository();

  Future<List<String>> getAvailableFlows() async {
    // Implement your logic to retrieve the list of available flows from a database or storage
    return [];
  }

  Future<void> saveFlow(String flowId, Map<String, dynamic> flowData) async {
    // Implement your logic to save the flow data to a database or storage
  }

  Future<Map<String, dynamic>> loadFlow(String flowId) async {
    // Implement your logic to load the flow data from a database or storage
    return {};
  }
}
