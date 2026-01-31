extension CollectionExtensions<T> on Iterable<T> {
  bool overlaps(Iterable<T> other) {
    return any((e) => other.contains(e));
  }
}
