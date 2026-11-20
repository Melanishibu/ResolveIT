import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';

/// One tab of [AppTabs].
@immutable
final class AppTab {
  const AppTab({required this.label, required this.child});

  final String label;
  final Widget child;
}

/// Tab bar with its content (US-28). Only the selected tab's content is built, so the tabs
/// size to their content and need no fixed height.
class AppTabs extends StatelessWidget {
  const AppTabs({super.key, required this.tabs});

  final List<AppTab> tabs;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.spacing;
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: colors.primary,
            unselectedLabelColor: colors.textSecondary,
            indicatorColor: colors.primary,
            dividerColor: colors.border,
            labelStyle: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              for (final tab in tabs)
                Tab(height: spacing.tabHeight, text: tab.label),
            ],
          ),
          SizedBox(height: spacing.l),
          Builder(
            builder: (context) {
              final controller = DefaultTabController.of(context);
              return AnimatedBuilder(
                animation: controller,
                builder: (context, _) => tabs[controller.index].child,
              );
            },
          ),
        ],
      ),
    );
  }
}
