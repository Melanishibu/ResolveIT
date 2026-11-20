import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time configuration (`--dart-define`). No secrets live here.
final class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  /// `flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=...`
  factory AppConfig.fromEnvironment() =>
      const AppConfig(apiBaseUrl: _apiBaseUrl);

  static const defaultApiBaseUrl = 'http://localhost:8080/api/v1';
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  final String apiBaseUrl;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
