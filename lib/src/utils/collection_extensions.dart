extension CollectionExtensions<T> on Iterable<T> {
  bool overlaps(Iterable<T> other) {
    return any((e) => other.contains(e));
  }

  Map<K, List<T>> groupBy<K>(K Function(T) key) {
    Map<K, List<T>> result = {};
    for (final e in this) {
      final k = key(e);
      result[k] = result[k] ?? [];
      result[k]!.add(e);
    }
    return result;
  }

  List<T> distinctBy<K>(K Function(T) key) {
    Map<K, T> result = {};
    for (final e in this) {
      final k = key(e);
      result[k] = e;
    }
    return result.values.toList();
  }

  List<R> flatten<R>(List<R> Function(T) key) {
    List<R> result = [];
    for (final e in this) {
      result.addAll(key(e));
    }
    return result;
  }
}

extension IterableExtensions<T> on Iterable<List<T>> {
  List<T> flatten() {
    List<T> result = [];
    for (final e in this) {
      result.addAll(e);
    }
    return result;
  }
}
