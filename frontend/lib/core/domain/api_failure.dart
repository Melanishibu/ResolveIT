/// How serious a failure is for the user.
///
/// A business-rule refusal (4xx) is a [warning]; a system or network failure is an [error].
enum FailureSeverity { warning, error }

/// Error codes that exist only in the frontend (they are never sent by the backend).
abstract final class ClientErrorCodes {
  /// Fallback when a response carries no recognisable Problem Details code.
  static const unknown = 'UNKNOWN_ERROR';

  /// The backend could not be reached at all.
  static const networkUnavailable = 'NETWORK_UNAVAILABLE';

  static const all = {unknown, networkUnavailable};
}

/// A failure reported by the backend (RFC 9457 Problem Details) or by the transport.
///
/// [code] is the stable error code; [params] carries the concrete values its message needs.
final class ApiFailure implements Exception {
  ApiFailure({
    required this.code,
    Map<String, String> params = const {},
    this.httpStatus,
  }) : params = Map.unmodifiable(params) {
    if (code.trim().isEmpty) {
      throw ArgumentError.value(code, 'code', 'must not be blank');
    }
  }

  factory ApiFailure.unknown({int? httpStatus}) =>
      ApiFailure(code: ClientErrorCodes.unknown, httpStatus: httpStatus);

  factory ApiFailure.networkUnavailable() =>
      ApiFailure(code: ClientErrorCodes.networkUnavailable);

  final String code;
  final Map<String, String> params;
  final int? httpStatus;

  FailureSeverity get severity {
    final status = httpStatus;
    if (code == ClientErrorCodes.networkUnavailable) {
      return FailureSeverity.error;
    }
    if (status == null || status >= 500) return FailureSeverity.error;
    return FailureSeverity.warning;
  }

  /// The support reference, when the backend sent one (for example with `INTERNAL_ERROR`).
  String? get traceId => params['traceId'];

  @override
  String toString() =>
      'ApiFailure($code, status: $httpStatus, params: $params)';
}
