class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Event &&
          runtimeType == other.runtimeType &&
          title == other.title;
}
