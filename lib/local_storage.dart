import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String callAcceptPref = "CALL_ACCEPT_PREF";
  static late SharedPreferences _shared;

  static Future<void> setCallAcceptTime({required DateTime dateTime}) async {
    await initPref();
    await _shared.setString(callAcceptPref, dateTime.toIso8601String());
  }

  static Future<void> deleteCallAcceptTime() async {
    await initPref();
    await _shared.remove(callAcceptPref);
  }

  static Future<DateTime?> getCallAcceptTime() async {
    await initPref();
    return await _shared.reload().then((value) {
      final dt = _shared.get(callAcceptPref);
      if (dt != null) {
        return DateTime.parse(dt as String);
      }
      return null;
    });
  }

  static initPref() async {
    _shared = await SharedPreferences.getInstance();
  }
}
