import 'dart:developer';

import 'package:flutter/foundation.dart';

class Log {
  static void d(String tag, String msg) {
    if (kDebugMode) {
      //print("${DateTime.now()}: $tag -> $msg");
      log("${DateTime.now()}: $tag -> $msg");
    }
  }
}
