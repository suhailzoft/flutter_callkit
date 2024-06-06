import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'entities/entities.dart';
import 'entities/enums.dart';
import 'local_storage.dart';

class FlutterCallkit {
  static const MethodChannel _channel =
      MethodChannel('flutter_callkit_channel');
  static const EventChannel _eventChannel =
      EventChannel('flutter_callkit_event_channel');

  static Stream<CallEvent?> get onEvent =>
      _eventChannel.receiveBroadcastStream().map(_receiveCallEvent);

  /// Show Callkit Incoming.
  /// On iOS, using Callkit. On Android, using a custom UI.
  static Future showCallkit(CallKitParams params) async {
    await _channel.invokeMethod("showCallkit", params.toJson());
  }

  static Future<bool> checkIsFullScreenNotificationAllowed() async {
    final hasPermission = await _channel.invokeMethod(
      "checkFullScreenNotificationPermission",
    );
    return hasPermission;
  }

  static Future requestFullScreenNotificationPermission() async {
    await _channel.invokeMethod(
      "requestFullScreenNotificationPermission",
    );
  }

  /// Show Miss Call Notification.
  /// Only Android
  static Future showMissCallNotification(CallKitParams params) async {
    await _channel.invokeMethod("showMissCallNotification", params.toJson());
  }

  /// Hide notification call for Android.
  /// Only Android
  static Future hideCallkit(CallKitParams params) async {
    await _channel.invokeMethod("hideCallkit", params.toJson());
  }

  /// Start an Outgoing call.
  /// On iOS, using Callkit(create a history into the Phone app).
  /// On Android, Nothing(only callback event listener).
  static Future startCall(CallKitParams params) async {
    await _channel.invokeMethod("startCall", params.toJson());
  }

  /// Muting an Ongoing call.
  /// On iOS, using Callkit(update the ongoing call ui).
  /// On Android, Nothing(only callback event listener).
  static Future muteCall(String id, {bool isMuted = true}) async {
    await _channel.invokeMethod("muteCall", {'id': id, 'isMuted': isMuted});
  }

  /// Get Callkit Mic Status (muted/unmuted).
  /// On iOS, using Callkit(update call ui).
  /// On Android, Nothing(only callback event listener).
  static Future<bool> isMuted(String id) async {
    return (await _channel.invokeMethod("isMuted", {'id': id})) as bool? ??
        false;
  }

  /// Hold an Ongoing call.
  /// On iOS, using Callkit(update the ongoing call ui).
  /// On Android, Nothing(only callback event listener).
  static Future holdCall(String id, {bool isOnHold = true}) async {
    await _channel.invokeMethod("holdCall", {'id': id, 'isOnHold': isOnHold});
  }

  /// End an Incoming/Outgoing call.
  /// On iOS, using Callkit(update a history into the Phone app).
  /// On Android, Nothing(only callback event listener).
  static Future endCall(String id) async {
    await _channel.invokeMethod("endCall", {'id': id});
  }

  /// Set call has been connected successfully.
  /// On iOS, using Callkit(update a history into the Phone app).
  /// On Android, Nothing(only callback event listener).
  static Future setCallConnected(String id) async {
    await _channel.invokeMethod("callConnected", {'id': id});
  }

  /// End all calls.
  static Future endAllCalls() async {
    await _channel.invokeMethod("endAllCalls");
  }

  /// Get active calls.
  /// On iOS: return active calls from Callkit.
  /// On Android: only return last call
  static Future<dynamic> activeCalls() async {
    return await _channel.invokeMethod("activeCalls");
  }

  /// Get device push token VoIP.
  /// On iOS: return deviceToken for VoIP.
  /// On Android: return Empty
  static Future getDevicePushTokenVoIP() async {
    return await _channel.invokeMethod("getDevicePushTokenVoIP");
  }

  /// Silence CallKit events
  static Future silenceEvents() async {
    return await _channel.invokeMethod("silenceEvents", true);
  }

  /// Unsilence CallKit events
  static Future unsilenceEvents() async {
    return await _channel.invokeMethod("silenceEvents", false);
  }

  /// Request permisstion show notification for Android(13)
  /// Only Android: show request permission post notification for Android 13+
  static Future requestNotificationPermission(dynamic data) async {
    return await _channel.invokeMethod("requestNotificationPermission", data);
  }

  static Future<CallKitAppState> getAppState() async {
    final appState = await _channel.invokeMethod("appState");
    return CallKitAppState.values
        .firstWhere((element) => element.name == appState.toUpperCase());
  }

  static CallEvent? _receiveCallEvent(dynamic data) {
    Event? event;
    Map<String, dynamic> body = {};

    if (data is Map) {
      event = Event.values.firstWhere((e) => e.name == data['event']);
      body = Map<String, dynamic>.from(data['body']);
      return CallEvent(body, event);
    }
    return null;
  }

  static Future getVoipToken() async {
    return await _channel.invokeMethod(
      "getVoipToken",
    );
  }

  static Future setCredentials({
    required String clientId,
    required String refreshToken,
  }) async {
    return await _channel.invokeMethod(
        "storeCredential", {"rToken": refreshToken, "clientID": clientId});
  }

  static Future<bool> checkIsIosCallDeclined() async {
    return await _channel.invokeMethod(
      "checkCallDeclined",
    );
  }

  static Future<bool> checkIsIosCallAnswered() async {
    return await _channel.invokeMethod(
      "checkCallAnswered",
    );
  }

  static Future<bool?> checkIsIosCallRedirect() async {
    return await _channel.invokeMethod(
      "callRedirect",
    );
  }

  static Future deleteIosCallRedirectValue() async {
    return await _channel.invokeMethod(
      "deleteCallPref",
    );
  }

  static Future setAppOpenedUsingCallKit({required bool status}) async {
    return await _channel.invokeMethod("setAppOpenedUsingCallKit", status);
  }

  static Future<bool> printLog({required String log}) async {
    return await _channel.invokeMethod("printData", log);
  }

  static Future getIosCallAcceptTime() async {
    return await LocalStorage.getCallAcceptTime();
  }

  static Future deleteIosCallAcceptTime() async {
    return await LocalStorage.deleteCallAcceptTime();
  }

  static Future setCallAcceptTime({required DateTime dateTime}) async {
    return await LocalStorage.setCallAcceptTime(dateTime: dateTime);
  }

  static Future<bool> checkIsCallConnecting() async {
    if (Platform.isIOS) {
      final bool isConnecting = await isCallConnecting();
      printLog(log: "$isConnecting");
      return isConnecting;
    } else {
      final DateTime? dt = await LocalStorage.getCallAcceptTime();
      if (dt != null &&
          DateTime.now().isBefore(dt.add(const Duration(minutes: 1)))) {
        return true;
      } else {
        return false;
      }
    }
  }

  static Future<bool> isCallConnecting() async {
    if (Platform.isIOS) {
      final val = await checkIsIosCallRedirect();
      if (val != null) {
        final bool value = val;
        if (value) {
          deleteIosCallRedirectValue();
        }
        return value;
      }
    }
    return false;
  }
}
