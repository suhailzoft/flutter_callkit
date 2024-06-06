/// Object CallEvent.
class CallEvent {
  Event event;
  dynamic body;

  CallEvent(this.body, this.event);
  @override
  String toString() => 'CallEvent( body: $body, event: $event)';
}

enum Event {
  actionDidUpdateDevicePushTokenVoip,
  actionCallIncoming,
  actionCallStart,
  actionCallAccept,
  actionCallDecline,
  actionCallEnded,
  actionCallTimeout,
  actionCallCallback,
  actionCallToggleHold,
  actionCallToggleMute,
  actionCallToggleDmtf,
  actionCallToggleGroup,
  actionCallToggleAudioSession,
  actionCallCustom,
}

/// Using extension for backward compatibility Dart SDK 2.17.0 and lower
extension EventX on Event {
  String get name {
    switch (this) {
      case Event.actionDidUpdateDevicePushTokenVoip:
        return 'com.bayshore.flutter_callkit.DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP';
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
      case Event.actionCallCallback:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_CALLBACK';
      case Event.actionCallToggleHold:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_TOGGLE_HOLD';
      case Event.actionCallToggleMute:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_TOGGLE_MUTE';
      case Event.actionCallToggleDmtf:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_TOGGLE_DMTF';
      case Event.actionCallToggleGroup:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_TOGGLE_GROUP';
      case Event.actionCallToggleAudioSession:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_TOGGLE_AUDIO_SESSION';
      case Event.actionCallCustom:
        return 'com.bayshore.flutter_callkit.ACTION_CALL_CUSTOM';
    }
  }
}
