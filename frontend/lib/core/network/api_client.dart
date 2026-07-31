import 'dart:async';
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
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(seconds: 60);

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
    final response = await _client
        .get(_uri(path, queryParameters), headers: _headers())
        .timeout(_requestTimeout);
    final decoded = _decodeResponse(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException(response.statusCode, 'Expected a JSON object response');
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _client
        .get(_uri(path, queryParameters), headers: _headers())
        .timeout(_requestTimeout);
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
    final response = await _client
        .post(_uri(path), headers: _headers(), body: jsonEncode(body))
        .timeout(_requestTimeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .patch(_uri(path), headers: _headers(), body: jsonEncode(body))
        .timeout(_requestTimeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await _client
        .delete(_uri(path), headers: _headers())
        .timeout(_requestTimeout);
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
    final streamedResponse = await request.send().timeout(_uploadTimeout);
    final response = await http.Response.fromStream(
      streamedResponse,
    ).timeout(_uploadTimeout);
    return _decodeResponse(response);
  }

  dynamic _decodeResponse(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw ApiException(
        response.statusCode,
        response.statusCode >= 200 && response.statusCode < 300
            ? 'El servidor devolvió una respuesta no válida.'
            : 'El servidor no pudo completar la solicitud.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(decoded);
      throw ApiException(response.statusCode, message);
    }

    return decoded;
  }

  String _extractErrorMessage(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      return 'La solicitud no pudo completarse.';
    }
    final detail = decoded['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final validation = (detail.first as Map).cast<String, dynamic>();
      final location = validation['loc'];
      final field = location is List && location.isNotEmpty
          ? location.last.toString()
          : 'campo';
      final translatedField = switch (field) {
        'email' => 'correo electrónico',
        'phone' => 'teléfono',
        'initial_password' => 'contraseña temporal',
        'full_name' => 'nombre',
        _ => field.replaceAll('_', ' '),
      };
      final rawMessage = (validation['msg'] ?? '').toString();
      if (field == 'email') return 'Ingresa un correo electrónico válido.';
      return rawMessage.isEmpty
          ? 'Revisa el campo $translatedField.'
          : '$translatedField: $rawMessage';
    }
    return (decoded['message'] ?? 'La solicitud no pudo completarse.')
        .toString();
  }
}
