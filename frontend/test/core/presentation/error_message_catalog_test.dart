import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/errors/error_message_catalog.dart';
import 'package:resolveit/core/presentation/errors/error_panel.dart';

import '../../support/test_app.dart';

void main() {
  final catalog = ErrorMessageCatalog.standard;

  test('interpolates params into the message', () {
    final message = catalog.resolve(
      ApiFailure(
        code: 'METHOD_NOT_ALLOWED',
        params: {'path': '/api/v1/x', 'method': 'DELETE'},
        httpStatus: 405,
      ),
      l10nEn,
    );
    expect(message.title, l10nEn.errorMethodNotAllowedTitle);
    expect(message.why, '/api/v1/x does not accept DELETE requests.');
  });

  test('shows "not available" for a param the backend did not send', () {
    final message = catalog.resolve(
      ApiFailure(code: 'RESOURCE_NOT_FOUND', httpStatus: 404),
      l10nEn,
    );
    expect(message.why, contains(l10nEn.errorValueUnavailable));
  });

  testWidgets(
    'Details shows the reference of an internal error, collapsed by default',
    (tester) async {
      await tester.pumpWidget(
        themedTestApp(
          ErrorPanel(
            failure: ApiFailure(
              code: 'INTERNAL_ERROR',
              params: {'traceId': 'trace-123'},
              httpStatus: 500,
            ),
          ),
        ),
      );
      expect(find.text(l10nEn.errorInternalErrorTitle), findsOneWidget);
      expect(find.textContaining('trace-123'), findsNothing);

      await tester.tap(find.byKey(const Key('error-details-toggle')));
      await tester.pumpAndSettle();

      expect(
        find.text(l10nEn.errorDetailsReference('trace-123')),
        findsOneWidget,
      );
    },
  );

  testWidgets('showErrorDialog renders the same structured panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedTestApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showErrorDialog(context, ApiFailure.networkUnavailable()),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error-panel')), findsOneWidget);
    expect(find.text(l10nEn.errorNetworkUnavailableTitle), findsOneWidget);

    await tester.tap(find.text(l10nEn.errorClose));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('error-panel')), findsNothing);
  });
}
