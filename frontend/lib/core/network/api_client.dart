import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'api_session.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (ApiSession.instance.hasToken) {
      headers['Authorization'] = 'Bearer ${ApiSession.instance.accessToken}';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _client.get(
      _uri(path, queryParameters),
      headers: _headers(),
    );
    final decoded = _decodeResponse(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException(response.statusCode, 'Expected a JSON object response');
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _client.get(
      _uri(path, queryParameters),
      headers: _headers(),
    );
    final decoded = _decodeResponse(response);
    final items = decoded is Map<String, dynamic>
        ? decoded['data'] ?? decoded['items'] ?? decoded['results']
        : decoded;
    if (items is List<dynamic>) return items;
    throw ApiException(response.statusCode, 'Expected a JSON list response');
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await _client.delete(_uri(path), headers: _headers());
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> uploadBytes(
    String path, {
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers(json: false));
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeResponse(response);
  }

  dynamic _decodeResponse(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? (decoded['detail']?.toString() ??
                decoded['message']?.toString() ??
                'Request failed')
          : 'Request failed';
      throw ApiException(response.statusCode, message);
    }

    return decoded;
  }
}
