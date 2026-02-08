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
}
