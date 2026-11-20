import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/errors/error_message_catalog.dart';

import '../../support/catalogue_gate.dart';
import '../../support/source_scan.dart';
import '../../support/test_app.dart';

// Scenario: Catalogue entries are complete
//   Given a catalogue entry is missing its "what to do" text
//   When I run flutter test
//   Then the catalogue gate test fails
void main() {
  final contract = loadContract(File('../contracts/error-codes.json'));
  final clientCodes = [
    for (final code in ClientErrorCodes.all) ContractCode(code, const {}),
  ];
  final appArb = loadArb(File('lib/l10n/app_en.arb'));
  final catalog = ErrorMessageCatalog.standard;

  group('Catalogue entries are complete', () {
    test(
      'every registry code has a complete catalogue entry (the gate passes on the real app)',
      () {
        expect(
          contract,
          isNotEmpty,
          reason: 'contracts/error-codes.json must list the backend codes',
        );

        final violations = catalogueGateViolations(
          codes: [...contract, ...clientCodes],
          arb: appArb,
          catalogCodes: catalog.entries.keys.toSet(),
        );

        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );

    test('a catalogue entry missing its "what to do" text fails the gate', () {
      final brokenArb = loadArb(
        File(
          'test/core/presentation/fixtures/catalogue_entry_missing_next_step.arb',
        ),
      );

      final violations = catalogueGateViolations(
        codes: const [ContractCode('SAMPLE_REFUSED', {})],
        arb: brokenArb,
        catalogCodes: const {'SAMPLE_REFUSED'},
      );

      expect(
        violations,
        contains(
          'SAMPLE_REFUSED: missing nextStep (what to do) (ARB key errorSampleRefusedNextStep)',
        ),
      );
    });

    test('each catalogue entry renders the texts of its own code', () {
      for (final code in [...contract, ...clientCodes]) {
        final failure = ApiFailure(
          code: code.code,
          params: {for (final param in code.requiredParams) param: '<$param>'},
        );

        final message = catalog.resolve(failure, l10nEn);

        final prefix = arbPrefix(code.code);
        expect(message.title, appArb['${prefix}Title'], reason: code.code);
        expect(
          message.nextStep,
          appArb['${prefix}NextStep'],
          reason: code.code,
        );
        // traceId is a support reference: it belongs in Details, not in the main text.
        for (final param in code.requiredParams.difference(const {'traceId'})) {
          expect(
            message.why,
            contains('<$param>'),
            reason: '${code.code} must show $param',
          );
        }
      }
    });

    test(
      'no free-text or ad-hoc error dialogs outside the shared error panel',
      () {
        final hits = forbiddenUsages(
          [
            RegExp(
              r'\b(AlertDialog|SimpleDialog|CupertinoAlertDialog|SnackBar)\s*\(',
            ),
            RegExp(r'\bshowDialog\s*[<(]'),
          ],
          allowedPrefixes: ['core/presentation/errors/'],
        );
        expect(hits, isEmpty, reason: hits.join('\n'));
      },
    );
  });
}
