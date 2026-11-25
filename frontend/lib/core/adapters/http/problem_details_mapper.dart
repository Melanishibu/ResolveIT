import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:resolveit/core/domain/api_failure.dart';

/// Translates a failed HTTP call into an [ApiFailure].
///
/// - RFC 9457 Problem Details with a `code` → that code and its `params`.
/// - Any other error response → `UNKNOWN_ERROR` (keeps the HTTP status).
/// - No response at all (connection refused, timeout) → `NETWORK_UNAVAILABLE`.
ApiFailure mapDioException(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return ApiFailure.networkUnavailable();
    default:
      break;
  }
  final response = exception.response;
  if (response == null) return ApiFailure.networkUnavailable();

  final status = response.statusCode;
  final body = _asJsonObject(response.data);
  final code = body?['code'];
  if (code is! String || code.trim().isEmpty) {
    return ApiFailure.unknown(httpStatus: status);
  }

  return ApiFailure(
    code: code,
    params: _params(body?['params']),
    httpStatus: status,
  );
}

Map<String, Object?>? _asJsonObject(Object? data) {
  if (data is Map) return data.map((key, value) => MapEntry('$key', value));
  if (data is String && data.isNotEmpty) {
    try {
      return _asJsonObject(jsonDecode(data));
    } on FormatException {
      return null;
    }
  }
  return null;
}

Map<String, String> _params(Object? raw) {
  if (raw is! Map) return const {};
  return raw.map((key, value) => MapEntry('$key', _paramText(value)));
}

String _paramText(Object? value) => switch (value) {
  null => '',
  final Iterable<Object?> items => items.map(_paramText).join(', '),
  _ => '$value',
};
