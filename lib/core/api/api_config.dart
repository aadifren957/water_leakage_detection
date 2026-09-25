import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  /// Default API base URL:
  /// - Web / Windows Desktop: http://localhost:5001/api
  /// - Android Emulator: http://10.0.2.2:5001/api
  /// - Real Mobile Device: http://LAN-IP:5001/api
  static String defaultBaseUrl = kIsWeb
      ? 'http://localhost:5001/api'
      : (defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:5001/api'
          : 'http://localhost:5001/api');

  static String baseUrl = defaultBaseUrl;

  static void updateBaseUrl(String newUrl) {
    var trimmed = newUrl.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.endsWith('/api')) {
      trimmed = '$trimmed/api';
    }
    baseUrl = trimmed;
  }
}
