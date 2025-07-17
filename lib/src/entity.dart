import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rwkv_studio/objectbox.g.dart';

@Entity()
class Embeddings {
  @Id()
  int id = 0;

  String? name;

  @HnswIndex(dimensions: 2, distanceType: VectorDistanceType.cosine)
  @Property(type: PropertyType.floatVector)
  List<double>? segment;
}

class ObjectBox {
  /// The Store of this app.
  late final Store store;

  static ObjectBox? _instance;

  static ObjectBox get instance => _instance!;

  ObjectBox._create(this.store) {
    // Add any additional setup code, e.g. build queries.
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    if (_instance != null) {
      return _instance!;
    }
    final docsDir = await getApplicationDocumentsDirectory();
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    final store = await openStore(directory: "${docsDir.path}\\box");

    _instance = ObjectBox._create(store);
    return _instance!;
  }
}
