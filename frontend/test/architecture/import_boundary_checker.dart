import 'dart:io';

/// Import-boundary rules: the frontend feature folder convention (RIT-US-29, AB#175, approved by
/// Melani Shibu 11/21/2026) plus the cross-cutting rules of AB#11 (package: imports, public feature
/// barrels, core never depends on features, only app/theme is shared from the composition root).
///
/// Every violation names the file, its layer and the broken rule. An empty list means clean.
final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// A forbidden import: [pattern] is matched against the import URI; [what] names it in the message.
final class _Ban {
  const _Ban(this.pattern, this.what);

  final String pattern;
  final String what;
}

const _flutter = _Ban('package:flutter/', 'Flutter');
const _riverpod = _Ban('riverpod', 'Riverpod');
const _dio = _Ban('package:dio', 'Dio');
const _http = _Ban('package:http/', 'HTTP');
const _json = _Ban('json_annotation', 'JSON serialisation');
const _convert = _Ban('dart:convert', 'JSON (dart:convert)');
const _web = _Ban('package:web/', 'browser APIs');
const _jsInterop = _Ban('dart:js_interop', 'browser APIs');
const _html = _Ban('dart:html', 'browser APIs');
const _l10n = _Ban('/l10n/', 'localisation (presentation)');
const _adapters = _Ban('/adapters/', 'core/adapters (technology)');
const _data = _Ban('/data/', 'the data layer');
const _interactor = _Ban('/interactor/', 'the interactor');
const _presentation = _Ban('/presentation/', 'presentation');
const _usecase = _Ban('/domain/usecase/', 'domain/usecase');
const _repository = _Ban('/domain/repository/', 'domain/repository');

const _pureDart = [
  _flutter,
  _riverpod,
  _dio,
  _http,
  _web,
  _jsInterop,
  _html,
  _l10n,
  _adapters,
];

/// The layer table of RIT-US-29: folder under `features/<feature>/` → what it must never import.
const _layerRules = <String, List<_Ban>>{
  'data/datasource': [_presentation, _interactor],
  'data/repository': [_presentation, _interactor],
  'domain/entity': [
    ..._pureDart,
    _json,
    _convert,
    _data,
    _interactor,
    _presentation,
  ],
  'domain/repository': [
    ..._pureDart,
    _json,
    _convert,
    _data,
    _interactor,
    _presentation,
  ],
  'domain/usecase': [
    ..._pureDart,
    _json,
    _convert,
    _data,
    _interactor,
    _presentation,
  ],
  'interactor': [..._pureDart, _data, _presentation],
  'presentation/presenter': [
    _data,
    _dio,
    _http,
    _adapters,
    _usecase,
    _repository,
  ],
  'presentation/router': [_data, _dio, _http, _adapters],
  'presentation/view': [_data, _dio, _http, _adapters, _interactor, _usecase],
  'widgets': [_data, _dio, _http, _adapters, _interactor],
};

/// The folders a feature may contain (RIT-US-29). Anything else is reported by [conventionViolations].
const conventionFolders = [
  'data/datasource',
  'data/repository',
  'domain/entity',
  'domain/repository',
  'domain/usecase',
  'interactor',
  'presentation/presenter',
  'presentation/router',
  'presentation/view',
  'widgets',
];

final _featurePath = RegExp(r'^features/([^/]+)/(.+)$');
final _featureName = RegExp(r'^[a-z][a-z0-9_]*$');

String? _feature(String path) =>
    RegExp(r'features/([a-z0-9_]+)/').firstMatch(path)?.group(1);

/// The layer of a file under `features/<feature>/`, or null outside a feature.
/// Returns `providers.dart` or `barrel` for the two top-level files, or `unknown` outside the convention.
String? _layerOf(String path) {
  if (!path.startsWith('features/')) return null;
  final match = _featurePath.firstMatch(path);
  // A file directly under features/ belongs to no feature.
  if (match == null) return 'unknown';
  final feature = match.group(1)!;
  final rest = match.group(2)!;
  // Feature folders are lowercase snake_case (package naming), so the import rules can match them.
  if (!_featureName.hasMatch(feature)) return 'unknown';
  if (rest == 'providers.dart') return 'providers.dart';
  if (rest == '$feature.dart') return 'barrel';
  for (final folder in conventionFolders) {
    if (rest.startsWith('$folder/')) return folder;
  }
  return 'unknown';
}

Iterable<(String path, File file)> _dartFiles(Directory libRoot) sync* {
  final rootPath = libRoot.absolute.path.replaceAll(r'\', '/');
  for (final file in libRoot.listSync(recursive: true).whereType<File>()) {
    final absolute = file.absolute.path.replaceAll(r'\', '/');
    if (!absolute.endsWith('.dart') ||
        absolute.endsWith('.g.dart') ||
        absolute.endsWith('.freezed.dart')) {
      continue;
    }
    yield (
      absolute.substring(rootPath.length).replaceFirst(RegExp('^/'), ''),
      file,
    );
  }
}

/// Files under `features/` that are outside the folder convention (scenario "Existing features
/// follow the convention").
List<String> conventionViolations(Directory libRoot) => [
  for (final (path, _) in _dartFiles(libRoot))
    if (_layerOf(path) == 'unknown')
      '$path is outside the feature folder convention; allowed: '
          '${conventionFolders.join(', ')}, providers.dart, <feature>.dart',
];

/// Checks every Dart file under [libRoot] (a `lib/` directory): the folder convention, the layer
/// rules and the cross-cutting import rules.
List<String> importBoundaryViolations(Directory libRoot) {
  final violations = <String>[...conventionViolations(libRoot)];
  for (final (path, file) in _dartFiles(libRoot)) {
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
          '$path uses a relative import ($imp); rule: use a package: import',
        );
      }
    }

    final layer = _layerOf(path);
    for (final ban in _layerRules[layer] ?? const <_Ban>[]) {
      for (final imp in imports) {
        if (imp.contains(ban.pattern)) {
          violations.add(
            '$path ($layer) imports $imp; rule: $layer must never import ${ban.what}',
          );
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
        violations.add(
          '$path reaches into feature "$other" internals: $imp; rule: other features import only $other.dart',
        );
      }
      if (path.startsWith('core/') && imp.contains('/features/')) {
        violations.add(
          '$path (core) depends on a feature: $imp; rule: core never imports features',
        );
      }
      final intoApp = RegExp(r'^package:[a-z0-9_]+/app/').hasMatch(imp);
      final themeOnly = RegExp(r'^package:[a-z0-9_]+/app/theme/').hasMatch(imp);
      final compositionRoot = path.startsWith('app/') || path == 'main.dart';
      if (!compositionRoot && intoApp && !themeOnly) {
        violations.add(
          '$path depends on the composition root: $imp; rule: only app/theme/ is shared',
        );
      }
    }
  }
  return violations;
}
