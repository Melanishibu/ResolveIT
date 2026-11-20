import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/csrf_token_source.dart';
import 'package:resolveit/core/adapters/http/unauthorized_interceptor.dart';
import 'package:resolveit/core/adapters/http/xsrf_interceptor.dart';

/// The shared HTTP client for the ResolveIT API.
///
/// `withCredentials` makes the browser send the session and XSRF cookies with cross-origin calls
/// (frontend on :5000, API on :8080).
///
/// [onUnauthorized] is called for every 401 response (the session has ended; RIT-US-05).
Dio createApiClient({
  required String baseUrl,
  required CsrfTokenSource csrfTokenSource,
  void Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      extra: const {'withCredentials': true},
      headers: const {'Accept': 'application/json, application/problem+json'},
    ),
  );
  dio.interceptors.add(XsrfInterceptor(csrfTokenSource));
  if (onUnauthorized != null) {
    dio.interceptors.add(UnauthorizedInterceptor(onUnauthorized));
  }
  return dio;
}
