import 'dart:async';

import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/app_button.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Search input (US-28). [onSearch] fires [debounce] after the last keystroke, and at once
/// when the field is cleared.
class AppSearchField extends StatefulWidget {
  const AppSearchField({super.key, required this.onSearch, this.hint});

  static const debounce = Duration(milliseconds: 300);

  final ValueChanged<String> onSearch;
  final String? hint;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final _controller = TextEditingController();
  Timer? _timer;

  void _changed(String text) {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(AppSearchField.debounce, () => widget.onSearch(text));
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    setState(() {});
    widget.onSearch('');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _controller,
      onChanged: _changed,
      style: context.textTheme.bodyLarge?.copyWith(
        color: context.appColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hint ?? l10n.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : AppIconButton(
                key: const Key('search-clear'),
                icon: Icons.close,
                semanticLabel: l10n.searchClear,
                onPressed: _clear,
              ),
      ),
    );
  }
}
