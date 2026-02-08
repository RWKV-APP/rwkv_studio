import 'dart:async';

extension ListExtension<T> on List<T> {
  Diff<T> diff(
    List<T> previous, {
    Object? Function(T)? keyExtractor,
    bool Function(T a, T b)? equals,
  }) {
    final removed = <T>[];
    final added = <T>[];
    final changed = <T>[];
    final unchanged = <T>[];

    final currentMap = <Object?, T>{};
    for (final item in this) {
      final key = keyExtractor?.call(item) ?? item;
      currentMap[key] = item;
    }

    final previousMap = <Object?, T>{};
    for (final item in previous) {
      final key = keyExtractor?.call(item) ?? item;
      previousMap[key] = item;
    }

    final allKeys = {...previousMap.keys, ...currentMap.keys};

    for (final key in allKeys) {
      final inPrevious = previousMap.containsKey(key);
      final inCurrent = currentMap.containsKey(key);

      if (inPrevious && !inCurrent) {
        removed.add(previousMap[key] as T);
      } else if (!inPrevious && inCurrent) {
        added.add(currentMap[key] as T);
      } else if (inPrevious && inCurrent) {
        final prevItem = previousMap[key] as T;
        final currItem = currentMap[key] as T;

        final isEqual =
            equals?.call(prevItem, currItem) ?? prevItem == currItem;

        if (isEqual) {
          unchanged.add(currItem);
        } else {
          changed.add(currItem);
        }
      }
    }

    return Diff<T>(
      removed: List.unmodifiable(removed),
      added: List.unmodifiable(added),
      changed: List.unmodifiable(changed),
      unchanged: List.unmodifiable(unchanged),
    );
  }
}

class Diff<T> {
  final List<T> removed;
  final List<T> added;
  final List<T> changed;
  final List<T> unchanged;

  const Diff({
    required this.removed,
    required this.added,
    required this.changed,
    required this.unchanged,
  });

  bool get hasChanges =>
      removed.isNotEmpty || added.isNotEmpty || changed.isNotEmpty;

  @override
  String toString() {
    return 'Diff(removed: ${removed.length}, added: ${added.length}, '
        'changed: ${changed.length}, unchanged: ${unchanged.length})';
  }
}

class ListChangesTransformer<T>
    extends StreamTransformerBase<List<T>, Diff<T>> {
  final Object? Function(T)? keyExtractor;
  final bool Function(T a, T b)? equals;

  const ListChangesTransformer({this.keyExtractor, this.equals});

  @override
  Stream<Diff<T>> bind(Stream<List<T>> stream) {
    List<T>? previousList;

    return Stream.eventTransformed(
      stream,
      (sink) => _DiffEventSink<T>(
        sink,
        keyExtractor: keyExtractor,
        equals: equals,
        onUpdatePrevious: (list) => previousList = list,
        getPrevious: () => previousList,
      ),
    );
  }
}

class _DiffEventSink<T> implements EventSink<List<T>> {
  final EventSink<Diff<T>> _sink;
  final Object? Function(T)? keyExtractor;
  final bool Function(T a, T b)? equals;
  final void Function(List<T>) onUpdatePrevious;
  final List<T>? Function() getPrevious;

  _DiffEventSink(
    this._sink, {
    this.keyExtractor,
    this.equals,
    required this.onUpdatePrevious,
    required this.getPrevious,
  });

  @override
  void add(List<T> currentList) {
    final previous = getPrevious();
    onUpdatePrevious(List.unmodifiable(currentList));

    if (previous == null) {
      _sink.add(
        Diff<T>(
          removed: const [],
          added: currentList,
          changed: const [],
          unchanged: const [],
        ),
      );
      return;
    }

    final diff = currentList.diff(
      previous,
      keyExtractor: keyExtractor,
      equals: equals,
    );
    _sink.add(diff);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  void close() {
    _sink.close();
  }
}

extension DiffStreamExtension<T> on Stream<List<T>> {
  Stream<Diff<T>> diff({
    Object? Function(T)? keyExtractor,
    bool Function(T a, T b)? equals,
  }) {
    return transform(
      ListChangesTransformer<T>(keyExtractor: keyExtractor, equals: equals),
    );
  }
}
