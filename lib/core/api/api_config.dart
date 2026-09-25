class ApiConfig {
  ApiConfig._();

  /// Default API base URL:
  /// - Live Cloud Backend: https://waterwatch-backend-t186.onrender.com/api
  static String defaultBaseUrl = 'https://waterwatch-backend-t186.onrender.com/api';

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
