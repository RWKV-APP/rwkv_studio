///  A base class for all objects that can be compared for equality.
///  This class provides a default implementation of [==] and [hashCode]
///
/// **Note:** You should **extend** [Equatable] instead of implement.
abstract class Equatable {
  const Equatable();

  List<Object?> get props;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    if (other is! Equatable) return false;
    if (other.props == props) return true;
    return isListEquals(other.props, props);
  }

  @override
  int get hashCode => Object.hashAll(props);
}

bool isListEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
