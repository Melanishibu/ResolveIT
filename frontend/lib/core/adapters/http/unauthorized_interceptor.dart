import 'package:dio/dio.dart';

/// Reports every 401 response from the API (RIT-US-05): the session has ended, so the app returns
/// to the login screen. The error itself still reaches the caller unchanged.
final class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor(this._onUnauthorized);

  final void Function() _onUnauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) _onUnauthorized();
    handler.next(err);
  }
}
