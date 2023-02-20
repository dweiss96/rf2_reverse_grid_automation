import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class Store {
  static const logPathKey = "LOG_PATH";
  static const reverseTopXKey = "REVERSE_TOP_X";

  static Future<String?> getLogPath() async => (await SharedPreferences.getInstance()).getString(logPathKey);
  static setLogPath(String newLogPath) async => (await SharedPreferences.getInstance()).setString(logPathKey, newLogPath);

  static Future<int?> getReverseTopX() async => (await SharedPreferences.getInstance()).getInt(reverseTopXKey);
  static setReverseTopX(int newReverseTopX) async => (await SharedPreferences.getInstance()).setInt(reverseTopXKey, newReverseTopX);
}
