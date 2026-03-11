import 'package:rwkv_studio/src/python/interpreter.dart';

class LocalMachineRepository {
  const LocalMachineRepository();

  Future<List<String>> getInterfaceIPAddress() async {
    return [];
  }

  Future<List<Python>> detectPythonInterpreters() async {
    return [];
  }

  Future<Python?> resolvePythonById(String id) async {
    return null;
  }
}
