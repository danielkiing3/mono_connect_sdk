extension IterableExtension<T> on Iterable<T>? {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return (this ?? []).firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
