import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/app_button.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// One column of an [AppDataTable]. [id] is what [AppDataTable.onSort] receives.
@immutable
final class AppTableColumn<T> {
  const AppTableColumn({
    required this.id,
    required this.label,
    required this.cell,
    this.sortable = false,
    this.columnWidth,
  });

  final String id;
  final String label;
  final Widget Function(T row) cell;
  final bool sortable;
  final TableColumnWidth? columnWidth;
}

/// The action offered at the end of each row (for example "View").
@immutable
final class AppTableRowAction<T> {
  const AppTableRowAction({required this.label, required this.onPressed});

  final String label;
  final void Function(T row) onPressed;
}

/// Data table with sortable headers, a row action and a pagination footer (US-28).
///
/// Controlled: [rows] is the current page; the presenter owns [page] (0-based), [pageSize],
/// [totalItems] and the sort, matching the API's `page/size/totalItems` and `sort` parameters.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChanged,
    this.sortColumnId,
    this.sortAscending = true,
    this.onSort,
    this.rowAction,
  });

  /// Pages shown as buttons before the footer switches to a window around the current page.
  static const maxPageButtons = 7;

  final List<AppTableColumn<T>> columns;
  final List<T> rows;
  final int page;
  final int pageSize;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final String? sortColumnId;
  final bool sortAscending;
  final ValueChanged<String>? onSort;
  final AppTableRowAction<T>? rowAction;

  int get pageCount => math.max(1, (totalItems / pageSize).ceil());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final sortIndex = columns.indexWhere((c) => c.id == sortColumnId);
    final action = rowAction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 0.0,
              ),
              child: DataTable(
                sortColumnIndex: sortIndex < 0 ? null : sortIndex,
                sortAscending: sortAscending,
                headingTextStyle: textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                dataTextStyle: textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                ),
                columns: [
                  for (final column in columns)
                    DataColumn(
                      label: Text(column.label),
                      columnWidth: column.columnWidth,
                      onSort: column.sortable && onSort != null
                          ? (_, _) => onSort!(column.id)
                          : null,
                    ),
                  if (action != null)
                    DataColumn(label: Text(l10n.tableActions)),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      cells: [
                        for (final column in columns) DataCell(column.cell(row)),
                        if (action != null)
                          DataCell(
                            AppButton(
                              label: action.label,
                              variant: AppButtonVariant.text,
                              onPressed: () => action.onPressed(row),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        // No rows: no footer and no paging; screens show an EmptyState instead.
        if (totalItems > 0)
          _Footer(
            page: page,
            pageSize: pageSize,
            totalItems: totalItems,
            pageCount: pageCount,
            onPageChanged: onPageChanged,
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.pageCount,
    required this.onPageChanged,
  });

  final int page;
  final int pageSize;
  final int totalItems;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  List<int> _visiblePages() {
    if (pageCount <= AppDataTable.maxPageButtons) {
      return [for (var p = 0; p < pageCount; p++) p];
    }
    final pages = {0, page - 1, page, page + 1, pageCount - 1};
    return pages.where((p) => p >= 0 && p < pageCount).toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final from = totalItems == 0 ? 0 : page * pageSize + 1;
    final to = math.min((page + 1) * pageSize, totalItems);
    return Padding(
      padding: EdgeInsets.only(top: spacing.m),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: spacing.l,
        runSpacing: spacing.s,
        children: [
          Text(
            l10n.tableShowing(from, to, totalItems),
            key: const Key('table-footer-summary'),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                key: const Key('table-previous-page'),
                icon: Icons.chevron_left,
                semanticLabel: l10n.tablePreviousPage,
                onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
              ),
              for (final p in _visiblePages())
                Semantics(
                  label: l10n.tablePage(p + 1),
                  selected: p == page,
                  child: AppButton(
                    key: Key('table-page-${p + 1}'),
                    label: '${p + 1}',
                    variant: p == page
                        ? AppButtonVariant.primary
                        : AppButtonVariant.text,
                    onPressed: p == page ? () {} : () => onPageChanged(p),
                  ),
                ),
              AppIconButton(
                key: const Key('table-next-page'),
                icon: Icons.chevron_right,
                semanticLabel: l10n.tableNextPage,
                onPressed: page < pageCount - 1
                    ? () => onPageChanged(page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
