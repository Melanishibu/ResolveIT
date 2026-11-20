import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/config/app_config.dart';
import 'package:resolveit/core/adapters/http/api_client.dart';
import 'package:resolveit/core/adapters/http/csrf_token_source.dart';

/// The shared API client. Feature data adapters take it from here (first used in US-04).
final apiClientProvider = Provider<Dio>((ref) {
  final dio = createApiClient(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    csrfTokenSource: const BrowserCsrfTokenSource(),
  );
  ref.onDispose(dio.close);
  return dio;
});
