/// The shared UI component library (US-28, AB#170; D2 replacement for Apex UI).
///
/// Features build every screen from these components and import only this file. Raw Material
/// controls (buttons, text fields, dropdowns, data tables, dialogs, snack bars) are rejected in
/// `lib/features/` by the guard test.
library;

export 'package:resolveit/core/presentation/errors/error_panel.dart';
export 'package:resolveit/core/presentation/widgets/app_button.dart';
export 'package:resolveit/core/presentation/widgets/app_card.dart';
export 'package:resolveit/core/presentation/widgets/app_chip.dart';
export 'package:resolveit/core/presentation/widgets/app_data_table.dart';
export 'package:resolveit/core/presentation/widgets/app_dropdown.dart';
export 'package:resolveit/core/presentation/widgets/app_form_section.dart';
export 'package:resolveit/core/presentation/widgets/app_search_field.dart';
export 'package:resolveit/core/presentation/widgets/app_tabs.dart';
export 'package:resolveit/core/presentation/widgets/app_text_field.dart';
export 'package:resolveit/core/presentation/widgets/app_toast.dart';
export 'package:resolveit/core/presentation/widgets/avatar_initials.dart';
export 'package:resolveit/core/presentation/widgets/confirm_dialog.dart';
export 'package:resolveit/core/presentation/widgets/feedback_states.dart';
export 'package:resolveit/core/presentation/widgets/page_header.dart';
export 'package:resolveit/core/presentation/widgets/placeholder_page.dart';
export 'package:resolveit/core/presentation/widgets/stat_card.dart';
