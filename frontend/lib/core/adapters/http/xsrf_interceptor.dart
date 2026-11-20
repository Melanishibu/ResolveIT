import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/csrf_token_source.dart';

/// Adds `X-XSRF-TOKEN` to every state-changing request (POST, PUT, PATCH, DELETE).
final class XsrfInterceptor extends Interceptor {
  XsrfInterceptor(this._tokenSource);

  static const headerName = 'X-XSRF-TOKEN';
  static const _stateChangingMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  final CsrfTokenSource _tokenSource;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_stateChangingMethods.contains(options.method.toUpperCase())) {
      final token = _tokenSource.read();
      if (token != null) options.headers[headerName] = token;
    }
    handler.next(options);
  }
}
