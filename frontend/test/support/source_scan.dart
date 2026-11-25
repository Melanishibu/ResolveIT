import 'dart:io';

/// A source line in `lib/` that matched a forbidden pattern.
String _describe(String path, int line, String text) =>
    '$path:$line  ${text.trim()}';

/// The hand-written Dart files under `lib/` (generated localisation code excluded), as
/// '/'-separated paths relative to `lib/`.
Map<String, String> libSources() {
  final root = Directory('lib');
  final sources = <String, String>{};
  for (final file in root.listSync(recursive: true).whereType<File>()) {
    final path = file.path
        .replaceAll(r'\', '/')
        .replaceFirst(RegExp(r'^lib/'), '');
    if (!path.endsWith('.dart') || path.startsWith('l10n/')) continue;
    sources[path] = file.readAsStringSync();
  }
  return sources;
}

/// Lines (comments stripped) that match any of [patterns], in files not under [allowedPrefixes].
/// When [onlyPrefixes] is given, only files under those prefixes are scanned (added for US-28).
List<String> forbiddenUsages(
  List<RegExp> patterns, {
  List<String> allowedPrefixes = const [],
  List<String>? onlyPrefixes,
}) {
  final hits = <String>[];
  libSources().forEach((path, source) {
    if (allowedPrefixes.any(path.startsWith)) return;
    if (onlyPrefixes != null && !onlyPrefixes.any(path.startsWith)) return;
    final lines = source.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final code = lines[i].replaceFirst(RegExp(r'//.*$'), '');
      if (patterns.any((pattern) => pattern.hasMatch(code))) {
        hits.add(_describe('lib/$path', i + 1, lines[i]));
      }
    }
  });
  return hits;
}
