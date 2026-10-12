import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Structured API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isConnectionError;
  final bool isUnauthorized;

  ApiException({
    required this.message,
    this.statusCode,
    this.isConnectionError = false,
    this.isUnauthorized = false,
  });

  @override
  String toString() => message;
}

/// Centralized HTTP API Client for CogniFocus-AI
class ApiClient {
  String _baseUrl;
  String? _authToken;
  final http.Client _client;

  ApiClient({String? baseUrl, String? authToken, http.Client? client})
    : _baseUrl = ApiConfig.normalizeUrl(baseUrl ?? ApiConfig.defaultServerUrl),
      _authToken = authToken,
      _client = client ?? _createDefaultClient();

  /// Create default HTTP client with standard certificate validation
  static http.Client _createDefaultClient() {
    return http.Client();
  }


  String get baseUrl => _baseUrl;
  String? get authToken => _authToken;

  void updateBaseUrl(String newUrl) {
    _baseUrl = ApiConfig.normalizeUrl(newUrl);
  }

  void setAuthToken(String? token) {
    _authToken = token;
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
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';

    if (queryParams != null && queryParams.isNotEmpty) {
      final formattedParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null) {
          formattedParams[key] = value.toString();
        }
      });
      return Uri.parse(fullUrl).replace(queryParameters: formattedParams);
    }
    return Uri.parse(fullUrl);
  }

  /// Perform GET request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    final uri = _buildUri(path, queryParams);
    debugPrint('[ApiClient] HTTP GET $uri');
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(ApiConfig.receiveTimeout);
      return _processResponse(response, uri);
    } catch (e) {
      throw _handleError(e, uri);
    }
  }

  /// Perform POST request
  Future<dynamic> post(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    debugPrint('[ApiClient] HTTP POST $uri');
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);
      return _processResponse(response, uri);
    } catch (e) {
      throw _handleError(e, uri);
    }
  }

  /// Perform PUT request
  Future<dynamic> put(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    debugPrint('[ApiClient] HTTP PUT $uri');
    try {
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);
      return _processResponse(response, uri);
    } catch (e) {
      throw _handleError(e, uri);
    }
  }

  /// Perform DELETE request
  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    debugPrint('[ApiClient] HTTP DELETE $uri');
    try {
      final response = await _client
          .delete(uri, headers: _buildHeaders())
          .timeout(ApiConfig.receiveTimeout);
      return _processResponse(response, uri);
    } catch (e) {
      throw _handleError(e, uri);
    }
  }

  /// Process HTTP Response and map to JSON or throw ApiException
  dynamic _processResponse(http.Response response, Uri uri) {
    final statusCode = response.statusCode;
    dynamic body;

    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body);
      }
    } catch (_) {
      body = {'message': response.body};
    }

    final method = response.request?.method ?? 'REQ';
    debugPrint('[ApiClient] HTTP $method $uri -> Status: $statusCode');

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }

    final message = body is Map
        ? (body['message'] ?? body['error'] ?? 'Server error ($statusCode)')
        : 'Server returned error status $statusCode';

    if (statusCode == 401) {
      debugPrint('[ApiClient] Unauthorized 401 on $uri');
      throw ApiException(
        message: message.toString(),
        statusCode: 401,
        isUnauthorized: true,
      );
    }

    throw ApiException(message: message.toString(), statusCode: statusCode);
  }

  /// Process errors (SocketException, Timeout, Handshake, etc.)
  ApiException _handleError(dynamic error, Uri uri) {
    if (error is ApiException) {
      return error;
    }

    final exceptionType = error.runtimeType.toString();
    debugPrint(
      '[ApiClient] Connection failure: URI=$uri, ExceptionType=$exceptionType, Details=$error',
    );

    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException) {
      return ApiException(
        message:
            'Unable to reach backend at $_baseUrl ($exceptionType). Please verify the laptop IP address and ensure the Flask server is running.',
        isConnectionError: true,
      );
    }

    if (error is TimeoutException) {
      return ApiException(
        message:
            'Connection timed out while contacting $_baseUrl ($exceptionType). Please check network connectivity.',
        isConnectionError: true,
      );
    }

    return ApiException(message: error.toString(), isConnectionError: false);
  }

  /// Diagnostic Server Ping: checks backend root "/" endpoint
  Future<Map<String, dynamic>> testConnection([String? testUrl]) async {
    final targetUrl = ApiConfig.normalizeUrl(testUrl ?? _baseUrl);
    final candidates = <String>[targetUrl];

    if (targetUrl.startsWith('http://')) {
      candidates.add(targetUrl.replaceFirst('http://', 'https://'));
    } else if (targetUrl.startsWith('https://')) {
      candidates.add(targetUrl.replaceFirst('https://', 'http://'));
    }

    final parsed = Uri.tryParse(targetUrl);
    if (parsed != null && !parsed.hasPort && parsed.host.isNotEmpty) {
      final withPort = parsed.replace(port: 5000).toString();
      if (!candidates.contains(withPort)) candidates.add(withPort);
      final withPortAlt = withPort.startsWith('http://')
          ? withPort.replaceFirst('http://', 'https://')
          : withPort.replaceFirst('https://', 'http://');
      if (!candidates.contains(withPortAlt)) candidates.add(withPortAlt);
    }

    dynamic lastError;
    for (final candidate in candidates) {
      final uri = Uri.parse('$candidate/');
      try {
        debugPrint('[ApiClient] Testing connection to candidate: $uri');
        final response = await _client
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data['status'] == 'online') {
            return {
              'success': true,
              'detected_url': candidate,
              'message':
                  'Connected: ${data['app']} v${data['version'] ?? '2.0.0'} (${candidate.startsWith('https') ? 'HTTPS' : 'HTTP'})',
              'data': data,
            };
          }
        }
      } catch (e) {
        lastError = e;
        debugPrint(
          '[ApiClient] Ping candidate failed: URI=$uri, ExceptionType=${e.runtimeType}, Details=$e',
        );
      }
    }

    return {
      'success': false,
      'message':
          'Failed to reach $targetUrl ($lastError). Ensure phone and laptop are on the same Wi-Fi and port 5000 is open.',
    };
  }

  void dispose() {
    _client.close();
  }
}
