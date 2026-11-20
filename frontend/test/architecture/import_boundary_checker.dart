import 'dart:io';

/// Import-boundary rules (clean-architecture skill, references/flutter.md §6, plus two extras
/// agreed in the AB#11 plan). Returns one line per violation; an empty list means clean.
final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

const _technology = [
  'package:flutter/',
  'riverpod',
  'package:dio',
  'package:http/',
  'json_annotation',
  'shared_preferences',
  'package:web/',
  'dart:js_interop',
  'dart:html',
  '/l10n/',
];

const _forbidden = <String, List<String>>{
  'domain': [..._technology, '/application/', '/adapters/', '/presentation/'],
  'application': [..._technology, '/adapters/', '/presentation/'],
  'presentation': ['package:dio', 'package:http/', '/adapters/data/'],
  'data': ['/presentation/'],
};

String? _feature(String path) =>
    RegExp(r'features/([a-z0-9_]+)/').firstMatch(path)?.group(1);

/// Checks every Dart file under [libRoot] (a `lib/` directory).
List<String> importBoundaryViolations(Directory libRoot) {
  final rootPath = libRoot.absolute.path.replaceAll(r'\', '/');
  final violations = <String>[];
  for (final file in libRoot.listSync(recursive: true).whereType<File>()) {
    final absolute = file.absolute.path.replaceAll(r'\', '/');
    if (!absolute.endsWith('.dart') ||
        absolute.endsWith('.g.dart') ||
        absolute.endsWith('.freezed.dart')) {
      continue;
    }
    final path = absolute
        .substring(rootPath.length)
        .replaceFirst(RegExp('^/'), '');
    final folders = path.split('/')..removeLast();
    final imports = _directive
        .allMatches(file.readAsStringSync())
        .map((m) => m.group(1)!)
        .toList();

    // Generated localisation code (flutter gen-l10n) imports its siblings relatively.
    final generated = path.startsWith('l10n/');
    for (final imp in imports) {
      if (!generated &&
          !imp.startsWith('package:') &&
          !imp.startsWith('dart:')) {
        violations.add(
          '$path uses a relative import ($imp); use a package: import',
        );
      }
    }
    for (final entry in _forbidden.entries) {
      if (!folders.contains(entry.key)) continue;
      for (final imp in imports) {
        for (final bad in entry.value) {
          if (imp.contains(bad)) {
            violations.add('$path (${entry.key}) imports $imp');
          }
        }
      }
    }
    final own = _feature(path);
    for (final imp in imports) {
      final other = _feature(imp);
      if (own != null &&
          other != null &&
          other != own &&
          !imp.endsWith('features/$other/$other.dart')) {
        violations.add('$path reaches into feature "$other" internals: $imp');
      }
      if (path.startsWith('core/') && imp.contains('/features/')) {
        violations.add('$path (core) depends on a feature: $imp');
      }
      final intoApp = RegExp(r'^package:[a-z0-9_]+/app/').hasMatch(imp);
      final themeOnly = RegExp(r'^package:[a-z0-9_]+/app/theme/').hasMatch(imp);
      final compositionRoot = path.startsWith('app/') || path == 'main.dart';
      if (!compositionRoot && intoApp && !themeOnly) {
        violations.add(
          '$path depends on the composition root (only app/theme/ is shared): $imp',
        );
      }
    }
  }
  return violations;
}
