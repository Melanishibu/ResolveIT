import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/users/users.dart';
import 'package:resolveit/features/incident/incident.dart';

/// Debug-only component gallery (US-28, AB#170): every component of the shared library in every
/// state. Registered only in debug builds (see `appRouterProvider`), so it never ships.
///
/// The section titles and sample data below are developer-facing literals and deliberately not
/// in the ARB file (approved by Melani Shibu 11/20/2026); the components' own texts come from it.
class ComponentGalleryView extends StatefulWidget {
  const ComponentGalleryView({super.key});

  static const path = '/dev/components';

  /// Also used to prove that release builds contain no gallery.
  static const title = 'ResolveIT component gallery';

  /// Every interactive component in the gallery, for the keyboard-accessibility test.
  static const interactiveKeys = <Key>[
    Key('gallery-button-primary'),
    Key('gallery-button-secondary'),
    Key('gallery-button-text'),
    Key('gallery-button-danger'),
    Key('gallery-button-icon'),
    Key('gallery-icon-button'),
    Key('gallery-text-field'),
    Key('gallery-required-field'),
    Key('gallery-password-field'),
    Key('gallery-dropdown'),
    Key('gallery-search'),
    Key('gallery-tabs'),
    Key('gallery-table'),
    Key('gallery-empty-action'),
    Key('gallery-confirm-open'),
    Key('gallery-confirm-danger-open'),
    Key('gallery-toast-open'),
  ];

  @override
  State<ComponentGalleryView> createState() => _ComponentGalleryViewState();
}

final class _SampleIncident {
  const _SampleIncident(this.number, this.title, this.priority);

  final int number;
  final String title;
  final Priority priority;

  String get ticket => 'INC-2026-${number.toString().padLeft(5, '0')}';
}

class _ComponentGalleryViewState extends State<ComponentGalleryView> {
  static const _pageSize = 20;
  static final _incidents = [
    for (var i = 1; i <= 45; i++)
      _SampleIncident(
        i,
        'Sample incident $i',
        Priority.values[i % Priority.values.length],
      ),
  ];

  String? _dropdownValue = 'SOFTWARE';
  String _lastSearch = '';
  int _page = 0;
  String _sortColumn = 'ticket';
  bool _sortAscending = true;

  List<_SampleIncident> get _sortedPage {
    final sorted = [..._incidents]
      ..sort((a, b) {
        final result = _sortColumn == 'priority'
            ? a.priority.index.compareTo(b.priority.index)
            : a.number.compareTo(b.number);
        return _sortAscending ? result : -result;
      });
    return sorted.skip(_page * _pageSize).take(_pageSize).toList();
  }

  void _sort(String column) => setState(() {
    _sortAscending = column == _sortColumn ? !_sortAscending : true;
    _sortColumn = column;
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: ComponentGalleryView.title,
              subtitle: 'Debug builds only · every component in every state',
            ),
            _Section('Buttons', [
              for (final variant in AppButtonVariant.values) ...[
                AppButton(
                  key: Key('gallery-button-${variant.name}'),
                  label: 'Save (${variant.name})',
                  variant: variant,
                  onPressed: () {},
                ),
                AppButton(
                  key: Key('gallery-button-${variant.name}-disabled'),
                  label: 'Disabled (${variant.name})',
                  variant: variant,
                  onPressed: null,
                ),
                AppButton(
                  key: Key('gallery-button-${variant.name}-loading'),
                  label: 'Loading (${variant.name})',
                  variant: variant,
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
              AppButton(
                key: const Key('gallery-button-icon'),
                label: 'Create Incident',
                icon: Icons.add,
                onPressed: () {},
              ),
              AppIconButton(
                key: const Key('gallery-icon-button'),
                icon: Icons.edit_outlined,
                semanticLabel: 'Edit',
                onPressed: () {},
              ),
              const AppIconButton(
                key: Key('gallery-icon-button-disabled'),
                icon: Icons.delete_outline,
                semanticLabel: 'Delete (disabled)',
                onPressed: null,
              ),
            ]),
            const _Section('Text fields', [
              _Field(
                AppTextField(
                  key: Key('gallery-text-field'),
                  label: 'Title',
                  hint: 'e.g. Unable to access accounting software',
                ),
              ),
              _Field(
                AppTextField(
                  key: Key('gallery-required-field'),
                  label: 'Title',
                  isRequired: true,
                  maxLength: 120,
                  errorText: 'Enter a title.',
                ),
              ),
              _Field(
                AppTextField(
                  key: Key('gallery-password-field'),
                  label: 'Password',
                  isPassword: true,
                  isRequired: true,
                ),
              ),
              _Field(
                AppTextField(
                  key: Key('gallery-text-field-disabled'),
                  label: 'Department',
                  enabled: false,
                ),
              ),
            ]),
            _Section('Dropdown and search', [
              _Field(
                AppDropdown<String>(
                  key: const Key('gallery-dropdown'),
                  label: 'Category',
                  isRequired: true,
                  value: _dropdownValue,
                  options: const [
                    AppDropdownOption('HARDWARE', 'Hardware'),
                    AppDropdownOption('SOFTWARE', 'Software'),
                    AppDropdownOption('NETWORK', 'Network'),
                  ],
                  onChanged: (value) => setState(() => _dropdownValue = value),
                ),
              ),
              _Field(
                AppDropdown<String>(
                  key: const Key('gallery-dropdown-error'),
                  label: 'Priority',
                  isRequired: true,
                  value: null,
                  errorText: 'Choose a priority.',
                  options: const [AppDropdownOption('HIGH', 'High')],
                  onChanged: (_) {},
                ),
              ),
              _Field(
                AppSearchField(
                  key: const Key('gallery-search'),
                  onSearch: (text) => setState(() => _lastSearch = text),
                ),
              ),
              Text('Last search: "$_lastSearch"'),
            ]),
            const _Section('Form section', [
              _Field(
                AppFormSection(
                  key: Key('gallery-form-section'),
                  title: 'Personal Info',
                  description: 'Read-only in PI_01',
                  children: [
                    AppTextField(label: 'Full Name', enabled: false),
                    AppTextField(label: 'Department', enabled: false),
                  ],
                ),
              ),
            ]),
            _Section('Cards', [
              const AppCard(
                key: Key('gallery-card'),
                child: Text('A white card with the token radius and shadow.'),
              ),
              for (final (label, value, icon, tone) in [
                (
                  'Open',
                  '5',
                  Icons.inbox_outlined,
                  context.appColors.statusOpen,
                ),
                (
                  'In Progress',
                  '2',
                  Icons.timelapse,
                  context.appColors.statusInProgress,
                ),
                (
                  'Resolved',
                  '12',
                  Icons.check_circle_outline,
                  context.appColors.statusResolved,
                ),
                (
                  'Closed',
                  '1',
                  Icons.archive_outlined,
                  context.appColors.statusClosed,
                ),
              ])
                StatCard(label: label, value: value, icon: icon, tone: tone),
            ]),
            _Section('Chips and avatar', [
              for (final priority in Priority.values) PriorityChip(priority),
              for (final status in IncidentStatus.values) StatusChip(status),
              for (final role in Role.values) RoleChip(role),
              const ActiveChip(isActive: true),
              const ActiveChip(isActive: false),
              AppChip(
                key: const Key('gallery-app-chip'),
                label: 'AppChip (any ChipColors token)',
                colors: context.appColors.statusAssigned,
              ),
              const AvatarInitials(
                key: Key('gallery-avatar'),
                initials: 'SJ',
                semanticLabel: 'Sarah Johnson',
              ),
            ]),
            _Section('Page header and tabs', [
              _Field(
                PageHeader(
                  key: const Key('gallery-page-header'),
                  title: 'My Incidents',
                  subtitle: 'Track the status of your IT requests',
                  actions: [
                    AppButton(
                      label: 'Create Incident',
                      icon: Icons.add,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const _Field(
                AppTabs(
                  key: Key('gallery-tabs'),
                  tabs: [
                    AppTab(
                      label: 'Personal Info',
                      child: Text('Personal info tab'),
                    ),
                    AppTab(label: 'Security', child: Text('Security tab')),
                  ],
                ),
              ),
            ]),
            _Section('Data table', [
              AppDataTable<_SampleIncident>(
                key: const Key('gallery-table'),
                columns: [
                  AppTableColumn(
                    id: 'ticket',
                    label: 'Incident #',
                    sortable: true,
                    cell: (row) => Text(row.ticket),
                  ),
                  AppTableColumn(
                    id: 'title',
                    label: 'Title',
                    cell: (row) => Text(row.title),
                  ),
                  AppTableColumn(
                    id: 'priority',
                    label: 'Priority',
                    sortable: true,
                    cell: (row) => PriorityChip(row.priority),
                  ),
                ],
                rows: _sortedPage,
                page: _page,
                pageSize: _pageSize,
                totalItems: _incidents.length,
                onPageChanged: (page) => setState(() => _page = page),
                sortColumnId: _sortColumn,
                sortAscending: _sortAscending,
                onSort: _sort,
                rowAction: AppTableRowAction(label: 'View', onPressed: (_) {}),
              ),
              AppDataTable<_SampleIncident>(
                key: const Key('gallery-table-empty'),
                columns: [
                  AppTableColumn(
                    id: 'ticket',
                    label: 'Incident #',
                    cell: (row) => Text(row.ticket),
                  ),
                ],
                rows: const [],
                page: 0,
                pageSize: _pageSize,
                totalItems: 0,
                onPageChanged: (_) {},
              ),
            ]),
            _Section('Feedback', [
              const LoadingState(key: Key('gallery-loading')),
              const LoadingState(
                key: Key('gallery-loading-message'),
                message: 'Loading incidents…',
              ),
              const EmptyState(
                key: Key('gallery-empty'),
                icon: Icons.inbox_outlined,
                message: 'No incidents yet.',
              ),
              EmptyState(
                key: const Key('gallery-empty-action'),
                icon: Icons.inbox_outlined,
                message: 'No incidents match your filters.',
                actionLabel: 'Clear filters',
                onAction: () {},
              ),
              _Field(
                ErrorPanel(
                  key: const Key('gallery-error-warning'),
                  failure: ApiFailure(
                    code: 'VALIDATION_FAILED',
                    params: const {'fields': 'title'},
                    httpStatus: 400,
                  ),
                ),
              ),
              _Field(
                ErrorPanel(
                  key: const Key('gallery-error-error'),
                  failure: ApiFailure(
                    code: 'INTERNAL_ERROR',
                    params: const {'traceId': 'trace-123'},
                    httpStatus: 500,
                  ),
                ),
              ),
              AppButton(
                key: const Key('gallery-confirm-open'),
                label: 'Open confirm dialog',
                variant: AppButtonVariant.secondary,
                onPressed: () => showConfirmDialog(
                  context,
                  title: 'Close incident?',
                  message: 'INC-2026-00001 will be closed.',
                ),
              ),
              AppButton(
                key: const Key('gallery-confirm-danger-open'),
                label: 'Open danger confirm dialog',
                variant: AppButtonVariant.secondary,
                onPressed: () => showConfirmDialog(
                  context,
                  title: 'Deactivate user?',
                  message: 'Sarah Johnson will no longer be able to log in.',
                  confirmLabel: 'Deactivate',
                  isDanger: true,
                ),
              ),
              AppButton(
                key: const Key('gallery-toast-open'),
                label: 'Show success toast',
                variant: AppButtonVariant.secondary,
                onPressed: () => AppToast.success(context, 'Incident created.'),
              ),
            ]),
            const _Section('Placeholder page', [
              _Field(PlaceholderPage(title: 'Dashboard')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(top: spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleLarge?.copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacing.m),
          Wrap(
            spacing: spacing.l,
            runSpacing: spacing.l,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ],
      ),
    );
  }
}

/// Gives form-like components a bounded width inside the gallery's Wrap.
class _Field extends StatelessWidget {
  const _Field(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: context.spacing.fieldMaxWidth, child: child);
}
