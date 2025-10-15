import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

/// Abstract HTTP client interface
abstract class HttpClient {
  Future<HttpResponse> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  });
  Future<HttpResponse> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  });
}

/// HTTP response wrapper
class HttpResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  HttpResponse(this.statusCode, this.body, this.headers);
}

/// Default HTTP client implementation
class DefaultHttpClient implements HttpClient {
  final http.Client _client;

  DefaultHttpClient({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<HttpResponse> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(timeout ?? const Duration(seconds: 30));
      return HttpResponse(response.statusCode, response.body, response.headers);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timeout');
    }
  }

  @override
  Future<HttpResponse> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout ?? const Duration(seconds: 30));
      return HttpResponse(response.statusCode, response.body, response.headers);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timeout');
    }
  }

  void close() {
    _client.close();
  }
}
