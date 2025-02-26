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

  static Future showCallkit(CallKitParams params) async {
    await _channel.invokeMethod("showCallkit", params.toJson());
  }

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

  static Future<String?> getVoipToken() async {
    return await _channel.invokeMethod(
      "getVoipToken",
    );
  }

  static Future<String?> getCachedProgram() async {
    return await _channel.invokeMethod(
      "getCachedProgram",
    );
  }

  static Future setCredentials({
    required String clientId,
    required String refreshToken,
    required String cognitoId,
  }) async {
    return await _channel.invokeMethod("storeCredential", {
      "rToken": refreshToken,
      "clientID": clientId,
      "cognitoId": cognitoId,
    });
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

  static Future getAndroidCallAcceptTime() async {
    return await LocalStorage.getAndroidCallAcceptTime();
  }

  static Future deleteAndroidCallAcceptTime() async {
    return await LocalStorage.deleteAndroidCallAcceptTime();
  }

  static Future setAndroidCallAcceptTime({required DateTime dateTime}) async {
    return await LocalStorage.setAndroidCallAcceptTime(dateTime: dateTime);
  }

  static Future<bool> checkIsCallConnecting() async {
    if (Platform.isIOS) {
      final bool isConnecting = await isIosCallConnecting();
      printLog(log: "$isConnecting");
      return isConnecting;
    } else {
      final DateTime? dt = await LocalStorage.getAndroidCallAcceptTime();
      if (dt != null &&
          DateTime.now().isBefore(dt.add(const Duration(minutes: 1)))) {
        return true;
      } else {
        return false;
      }
    }
  }

  static Future<bool> isIosCallConnecting() async {
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

  static Future showMissCallNotification(CallKitParams params) async {
    await _channel.invokeMethod("showMissCallNotification", params.toJson());
  }

  static Future hideCallkit(CallKitParams params) async {
    await _channel.invokeMethod("hideCallkit", params.toJson());
  }

  static Future startCall(CallKitParams params) async {
    await _channel.invokeMethod("startCall", params.toJson());
  }

  static Future endAllCalls() async {
    await _channel.invokeMethod("endAllCalls");
  }

  static Future<dynamic> activeCalls() async {
    return await _channel.invokeMethod("activeCalls");
  }
}
