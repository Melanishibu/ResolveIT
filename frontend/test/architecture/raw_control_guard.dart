import 'dart:io';

/// Raw Material controls that features must not use, and the shared component to use instead
/// (US-28, AB#170).
const rawControlReplacements = <String, String>{
  'ElevatedButton': 'AppButton (variant: primary)',
  'FilledButton': 'AppButton (variant: primary or danger)',
  'OutlinedButton': 'AppButton (variant: secondary)',
  'TextButton': 'AppButton (variant: text)',
  'TextField': 'AppTextField',
  'TextFormField': 'AppTextField',
  'DropdownButton': 'AppDropdown',
  'DropdownMenu': 'AppDropdown',
  'DataTable': 'AppDataTable',
  'AlertDialog': 'ConfirmDialog (errors: showErrorDialog)',
  'SnackBar': 'AppToast.success (errors: ErrorPanel)',
};

final _usage = {
  for (final name in rawControlReplacements.keys)
    name: RegExp('\\b$name\\s*(?:\\.\\w+\\s*)?[(<]'),
};

/// Every use of a raw Material control in a file under `<libRoot>/features/`. Each line names the
/// file and the App component to use instead. An empty list means the features are clean.
List<String> rawControlViolations(Directory libRoot) {
  final rootPath = libRoot.absolute.path.replaceAll(r'\', '/');
  final violations = <String>[];
  for (final file in libRoot.listSync(recursive: true).whereType<File>()) {
    final absolute = file.absolute.path.replaceAll(r'\', '/');
    if (!absolute.endsWith('.dart')) continue;
    final path = absolute
        .substring(rootPath.length)
        .replaceFirst(RegExp('^/'), '');
    if (!path.startsWith('features/')) continue;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final code = lines[i].replaceFirst(RegExp(r'//.*$'), '');
      _usage.forEach((name, pattern) {
        if (pattern.hasMatch(code)) {
          violations.add(
            '$path:${i + 1} uses $name; use ${rawControlReplacements[name]} '
            'from core/presentation/widgets/widgets.dart instead',
          );
        }
      });
    }
  }
  return violations;
}
