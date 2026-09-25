import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _httpClient = http.Client();
  String? _authToken;

  static const String _tokenStorageKey = 'waterwatch_auth_token';

  String? get token => _authToken;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_tokenStorageKey);
    } catch (_) {
      // Running in test or memory environment
    }
  }

  Future<void> setToken(String? token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString(_tokenStorageKey, token);
      } else {
        await prefs.remove(_tokenStorageKey);
      }
    } catch (_) {}
  }

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final fullUrl = '${ApiConfig.baseUrl}/$cleanPath';

    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return Uri.parse(fullUrl).replace(queryParameters: stringParams);
    }

    return Uri.parse(fullUrl);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await _httpClient
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message: 'Unable to connect to WaterWatch server. Please check your network or server URL.',
        statusCode: 503,
        code: 'NETWORK_ERROR',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Network connection failed: ${e.message}',
        statusCode: 503,
        code: 'CONNECTION_FAILED',
      );
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message: 'Unable to connect to WaterWatch server. Please verify backend is running.',
        statusCode: 503,
        code: 'NETWORK_ERROR',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Network connection failed: ${e.message}',
        statusCode: 503,
        code: 'CONNECTION_FAILED',
      );
    }
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await _httpClient
          .patch(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message: 'Unable to connect to WaterWatch server.',
        statusCode: 503,
        code: 'NETWORK_ERROR',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Network connection failed: ${e.message}',
        statusCode: 503,
        code: 'CONNECTION_FAILED',
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    final errorMessage = (decoded is Map<String, dynamic> && decoded['message'] != null)
        ? decoded['message'] as String
        : 'Request failed with status ${response.statusCode}';

    final errorCode = (decoded is Map<String, dynamic> && decoded['code'] != null)
        ? decoded['code'] as String
        : 'HTTP_${response.statusCode}';

    final errors = (decoded is Map<String, dynamic>) ? decoded['errors'] : null;

    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
      code: errorCode,
      errors: errors,
    );
  }
}
