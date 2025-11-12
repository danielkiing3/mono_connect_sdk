/// Event types from Mono Connect widget
enum MonoEventType {
  accountLinked('mono.connect.widget.account_linked'),
  widgetClosed('mono.connect.widget.closed'),
  modalClosed('mono.modal.closed'),
  widgetOpened('mono.connect.widget_opened'),
  modalLoad('mono.modal.onLoad'),
  unknown('unknown');

  const MonoEventType(this.value);
  final String value;

  static MonoEventType fromString(String value) {
    return MonoEventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MonoEventType.unknown,
    );
  }
}
