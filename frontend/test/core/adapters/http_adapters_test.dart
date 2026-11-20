import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/app/config/app_config.dart';
import 'package:resolveit/core/adapters/http/api_client.dart';
import 'package:resolveit/core/adapters/http/csrf_token_source.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/adapters/http/xsrf_interceptor.dart';
import 'package:resolveit/core/domain/api_failure.dart';

final class _FixedToken implements CsrfTokenSource {
  const _FixedToken(this.token);
  final String? token;
  @override
  String? read() => token;
}

RequestOptions _intercept(String method, String? token) {
  final options = RequestOptions(path: '/incidents', method: method);
  XsrfInterceptor(
    _FixedToken(token),
  ).onRequest(options, RequestInterceptorHandler());
  return options;
}

DioException _badResponse(int status, Object? data) {
  final request = RequestOptions(path: '/incidents');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: request,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  group('XsrfInterceptor', () {
    test('adds X-XSRF-TOKEN to state-changing requests', () {
      for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
        expect(
          _intercept(method, 'abc').headers[XsrfInterceptor.headerName],
          'abc',
          reason: method,
        );
      }
    });

    test('leaves safe requests and missing tokens alone', () {
      expect(
        _intercept(
          'GET',
          'abc',
        ).headers.containsKey(XsrfInterceptor.headerName),
        isFalse,
      );
      expect(
        _intercept(
          'POST',
          null,
        ).headers.containsKey(XsrfInterceptor.headerName),
        isFalse,
      );
    });

    test('reads the XSRF-TOKEN cookie value', () {
      expect(cookieValue('a=1; XSRF-TOKEN=abc%3D; b=2', 'XSRF-TOKEN'), 'abc=');
      expect(cookieValue('a=1', 'XSRF-TOKEN'), isNull);
      expect(cookieValue('XSRF-TOKEN=', 'XSRF-TOKEN'), isNull);
      expect(cookieValue(null, 'XSRF-TOKEN'), isNull);
      expect(
        const BrowserCsrfTokenSource().read(),
        isNull,
        reason: 'no browser in VM tests',
      );
    });
  });

  group('api client', () {
    test('defaults to the local API and sends cookies with every request', () {
      expect(
        AppConfig.fromEnvironment().apiBaseUrl,
        'http://localhost:8080/api/v1',
      );

      final dio = createApiClient(
        baseUrl: AppConfig.defaultApiBaseUrl,
        csrfTokenSource: const _FixedToken('t'),
      );

      expect(dio.options.baseUrl, AppConfig.defaultApiBaseUrl);
      expect(dio.options.extra['withCredentials'], isTrue);
      expect(dio.interceptors.whereType<XsrfInterceptor>(), hasLength(1));
    });
  });

  group('mapDioException', () {
    test('maps Problem Details to its code, params and status', () {
      final failure = mapDioException(
        _badResponse(400, {
          'code': 'VALIDATION_FAILED',
          'params': {
            'fields': ['title', 'priority'],
          },
        }),
      );
      expect(failure.code, 'VALIDATION_FAILED');
      expect(failure.params, {'fields': 'title, priority'});
      expect(failure.httpStatus, 400);
      expect(failure.severity, FailureSeverity.warning);
    });

    test('decodes a Problem Details body that arrives as text', () {
      final failure = mapDioException(
        _badResponse(
          404,
          '{"code":"RESOURCE_NOT_FOUND","params":{"path":"/x"}}',
        ),
      );
      expect(failure.code, 'RESOURCE_NOT_FOUND');
      expect(failure.params['path'], '/x');
    });

    test('maps a response without Problem Details to UNKNOWN_ERROR', () {
      final failure = mapDioException(_badResponse(503, 'Service Unavailable'));
      expect(failure.code, ClientErrorCodes.unknown);
      expect(failure.httpStatus, 503);
      expect(failure.severity, FailureSeverity.error);
    });

    test('maps an unreachable server to NETWORK_UNAVAILABLE', () {
      final failure = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/incidents'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(failure.code, ClientErrorCodes.networkUnavailable);
    });
  });
}
