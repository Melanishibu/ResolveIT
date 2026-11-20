import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:resolveit/app/config/app_config.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/errors/error_panel.dart';

import '../../support/test_app.dart';

// Scenario: Unknown error codes show a safe message
//   Given the API returns a Problem Details response with an unknown code
//   When the error is shown
//   Then the generic message is displayed with the code inside the collapsed Details
void main() {
  testWidgets('Unknown error codes show a safe message', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: AppConfig.defaultApiBaseUrl));
    DioAdapter(dio: dio).onGet(
      '/incidents/42',
      (server) => server.reply(
        409,
        // The raw RFC 9457 body, as the server sends it.
        jsonEncode({
          'type': 'about:blank',
          'title': 'Conflict',
          'status': 409,
          'detail': 'Raw backend text that must not be shown',
          'code': 'SOMETHING_NEW',
          'params': {'incidentId': '42'},
        }),
        headers: {
          Headers.contentTypeHeader: ['application/problem+json'],
        },
      ),
    );

    final failure = await tester.runAsync(() async {
      try {
        await dio.get<Object?>('/incidents/42');
        return null;
      } on DioException catch (exception) {
        return mapDioException(exception);
      }
    });
    expect(failure?.code, 'SOMETHING_NEW');

    await tester.pumpWidget(themedTestApp(ErrorPanel(failure: failure!)));
    await tester.pumpAndSettle();

    // The generic, safe message is shown ...
    expect(find.text(l10nEn.errorUnknownErrorTitle), findsOneWidget);
    expect(find.text(l10nEn.errorUnknownErrorWhy), findsOneWidget);
    expect(find.text(l10nEn.errorUnknownErrorNextStep), findsOneWidget);
    expect(find.textContaining('Raw backend text'), findsNothing);
    expect(failure.severity, FailureSeverity.warning);

    // ... and the code is not in the main text, only inside the collapsed Details.
    expect(find.textContaining('SOMETHING_NEW'), findsNothing);
    expect(find.byKey(const Key('error-details')), findsNothing);

    await tester.tap(find.byKey(const Key('error-details-toggle')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.errorDetailsCode('SOMETHING_NEW')), findsOneWidget);
    expect(find.text(l10nEn.errorDetailsStatus('409')), findsOneWidget);
  });
}
