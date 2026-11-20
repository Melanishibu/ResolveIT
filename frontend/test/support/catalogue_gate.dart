import 'dart:convert';
import 'dart:io';

/// One code from the backend registry (`contracts/error-codes.json`).
final class ContractCode {
  const ContractCode(this.code, this.requiredParams);

  final String code;
  final Set<String> requiredParams;
}

List<ContractCode> loadContract(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final codes = json['errorCodes']! as List<Object?>;
  return [
    for (final raw in codes.cast<Map<String, Object?>>())
      ContractCode(
        raw['code']! as String,
        (raw['requiredParams']! as List<Object?>).cast<String>().toSet(),
      ),
  ];
}

Map<String, Object?> loadArb(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

/// ARB key prefix of a code: RESOURCE_NOT_FOUND → errorResourceNotFound.
String arbPrefix(String code) =>
    'error${code.toLowerCase().split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join()}';

const _parts = {
  'Title': 'title',
  'Why': 'why',
  'NextStep': 'nextStep (what to do)',
};
final _placeholder = RegExp(r'\{(\w+)\}');

/// The front-end error-message gate (clean-architecture skill §3a, rule 2):
/// every code needs a catalogue entry with title, why and nextStep, and its texts may only use
/// the params the backend promises to send. Entries for unknown codes are stale.
List<String> catalogueGateViolations({
  required Iterable<ContractCode> codes,
  required Map<String, Object?> arb,
  required Set<String> catalogCodes,
}) {
  final violations = <String>[];
  final known = <String>{};
  for (final contract in codes) {
    known.add(contract.code);
    if (!catalogCodes.contains(contract.code)) {
      violations.add('${contract.code}: no entry in ErrorMessageCatalog');
    }
    final prefix = arbPrefix(contract.code);
    _parts.forEach((suffix, label) {
      final key = '$prefix$suffix';
      final text = arb[key];
      if (text is! String || text.trim().isEmpty) {
        violations.add('${contract.code}: missing $label (ARB key $key)');
        return;
      }
      final used = _placeholder
          .allMatches(text)
          .map((m) => m.group(1)!)
          .toSet();
      final unknown = used.difference(contract.requiredParams);
      if (unknown.isNotEmpty) {
        violations.add(
          '${contract.code}: $key uses params $unknown that the backend does not send',
        );
      }
    });
  }
  for (final stale in catalogCodes.difference(known)) {
    violations.add(
      '$stale: catalogue entry for a code that is not in the registry',
    );
  }
  return violations;
}
