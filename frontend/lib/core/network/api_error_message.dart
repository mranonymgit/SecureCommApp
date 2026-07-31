import 'dart:async';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiErrorMessage {
  const ApiErrorMessage._();

  static String from(Object error, {required String fallback}) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'La sesión expiró o las credenciales no son válidas.';
      }
      if (error.statusCode == 422) return error.message;
      if (error.statusCode == 502) {
        return 'Supabase no pudo guardar el archivo. Intenta nuevamente.';
      }
      if (error.message.trim().isNotEmpty) return error.message;
    }
    if (error is http.ClientException) {
      return 'No fue posible conectar con el servidor. Revisa tu conexión e intenta nuevamente.';
    }
    if (error is TimeoutException) {
      return 'El servidor tardó demasiado en responder. Intenta nuevamente.';
    }
    return fallback;
  }
}
