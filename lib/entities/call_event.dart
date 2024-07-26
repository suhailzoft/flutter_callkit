/// Object CallEvent.
class CallEvent {
  Event event;
  dynamic body;

  CallEvent(this.body, this.event);
  @override
  String toString() => 'CallEvent( body: $body, event: $event)';
}

enum Event {
  actionCallIncoming,
  actionCallStart,
  actionCallAccept,
  actionCallDecline,
  actionCallEnded,
  actionCallTimeout,
}

/// Using extension for backward compatibility Dart SDK 2.17.0 and lower
extension EventX on Event {
  String get name {
    switch (this) {
      case Event.actionCallIncoming:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_INCOMING';
      case Event.actionCallStart:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_START';
      case Event.actionCallAccept:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_ACCEPT';
      case Event.actionCallDecline:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_DECLINE';
      case Event.actionCallEnded:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_ENDED';
      case Event.actionCallTimeout:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_TIMEOUT';
    }
  }
}
