import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/config/app_config.dart';
import 'package:resolveit/core/adapters/http/api_client.dart';
import 'package:resolveit/core/adapters/http/csrf_token_source.dart';
import 'package:resolveit/features/auth/auth.dart';

/// The shared API client. Feature data adapters get it through providers the composition root binds.
///
/// Any 401 response signs the user out, so the router returns to `/login` (RIT-US-05).
final apiClientProvider = Provider<Dio>((ref) {
  final dio = createApiClient(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    csrfTokenSource: const BrowserCsrfTokenSource(),
    onUnauthorized: () => ref.read(sessionProvider.notifier).signedOut(),
  );
  ref.onDispose(dio.close);
  return dio;
});
