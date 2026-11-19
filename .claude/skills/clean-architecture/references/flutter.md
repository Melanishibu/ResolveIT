# Flutter / Dart (VIPER, sVIPER, Riverpod)

How the clean architecture standard maps onto Flutter front ends. The Flutter apps use VIPER (or the sVIPER variant) with Riverpod for state and dependency injection. VIPER is a clean architecture in itself; the rules below make its boundaries explicit and enforceable. If a repo already has established sVIPER conventions that satisfy the dependency rule, keep its names and map them to the layers below.

## Contents
1. Where business rules live on the client
2. VIPER ↔ Clean/Hexagonal mapping
2a. Apex UI: the mandatory View layer
3. Folder layout
4. What each layer may import
5. Code shapes
6. Import-boundary test (mandatory)
7. Testing strategy

## 1. Where business rules live on the client

The backend bounded context is the source of truth for business rules and invariants. The client's domain layer holds:
- the client-side model of the bounded context (entities and value objects returned by the backend API, translated through mappers),
- validation rules duplicated for user experience (instant feedback). These are mirrored from the backend spec and never the only enforcement,
- pure presentation-independent logic (e.g. "pack expires within 24 h → warning").

Never put a rule *only* on the client. If the ADO story says something is enforced, the backend enforces it, and the client may additionally pre-check it.

## 2. VIPER ↔ Clean/Hexagonal mapping

| VIPER part | Clean/Hexagonal layer | Responsibility |
|---|---|---|
| **E**ntity | Domain | Immutable entities and value objects, pure Dart |
| **I**nteractor | Application (use case) | One use case: calls outbound ports (repositories/gateways), applies domain logic, returns domain objects or failures |
| *(ports)* | Application | Abstract repository/gateway classes the interactor needs |
| **P**resenter | Inbound adapter (presentation) | Calls interactors, turns results into immutable view state; Riverpod `Notifier`/`AsyncNotifier` |
| **V**iew | Inbound adapter (presentation) | **Apex UI** widgets (`ApexFormScaffold`, `ApexUi*`) only render state and forward user intents to the presenter. No logic, no I/O |
| **R**outer | Inbound adapter (presentation) | Entry from the Apex menu (`ApexMenuItem.screenBuilder`) and navigation between the module's screens |
| *(data)* | Outbound adapters | API clients (Dio/http), DTOs with JSON, local storage, repository implementations, DTO ↔ domain mappers |
| *(di)* | Composition root | Riverpod providers that bind port → implementation |

## 2a. Apex UI: the mandatory View layer

Every Flutter product builds its screens from **Apex UI**: the shared, versioned package set in the Apex UI UX project in Azure DevOps. The product supplies domain, application, presenters and adapters; Apex supplies the shell, menu, form container, design system and widgets. Before writing screen code, read these files in that repo: `docs/CONSUMING.md`, `docs/design_system/AGENT.md`, `docs/design_system/guidelines/screens/master_screen.md` and the relevant `guidelines/*.md`.

### Consume it, never copy it
- Pin the version in `apex_ui.version` at the repo root. Fetch with `tool/fetch_apex_ui.ps1` / `.sh` (copied from the Apex repo) into a gitignored `.apex/` folder. Depend through `path:` entries:
  ```yaml
  dependencies:
    apex_app_shell:            # re-exports apex_ui_core
      path: .apex/apex_ui/packages/apex_app_shell
  ```
  CI uses the Apex `consume-apex-ui.yml` template before `flutter pub get`.
- Never copy Apex source into the product, fork it, use a git or local-path reference to the Apex repo, or write look-alike widgets.
- If a needed component or behaviour is missing (e.g. a barcode-scan field, arrow-key table navigation), raise it on the Apex backlog and use the closest existing component meanwhile. Shared UI belongs in Apex.
- Upgrade by changing `apex_ui.version`, re-fetching and reading the Apex `CHANGELOG.md`.

### UI of a base platform (erpbase or similar)
- **Apex owns the frame.** The application shell, menu, navigation, sign-in screen, design system and every product screen are Apex UI.
  - A product never uses a platform's widget or UI packages in its own screens: no `erp_ui_kit`, no `erp_core`, no `erp_api`.
  - A platform never contributes a menu.
  - The login screen is an Apex screen. The OIDC flow (Authorization Code + PKCE against the platform's Keycloak) runs behind the product's own auth port, or behind Apex's `apex_auth` package once it exists.
- **Platform screens are embedded, not rebuilt.** A platform's own feature UI is used as-is through **Apex's plugin system** (`apex_plugin_host`). Examples are the approval engine (For my approval cards, My requests, delegations, trace) and the workflow designer.
  - An Apex menu entry (add-on config, with a permission key) opens the platform page in an `ApexPluginScreen`.
  - The page gets the session through the Apex plugin protocol (`PLUGIN_READY` → `INIT_SESSION`).
  - Product screens may open such a page in context, for example the trace of one approval.
- Data the product shows in its own screens comes from platform **backend contracts**: REST, OIDC and events.
- If Apex lacks something, add it to Apex.
- Why: one consistent look and navigation, without rebuilding platform features that the platform team owns and evolves.

### Integration points (composition root, `lib/app/`)
| Apex extension point | Product provides | Layer |
|---|---|---|
| `MaterialApp(theme: ApexTheme.light(), darkTheme: ApexTheme.dark())`, `ApexLocalizations.delegate` | app setup | composition root |
| `ApexShell` + `ApexMenuSection` / `ApexMenuItem` (or menu JSON + `ApexActionRegistry`) | the product menu. Each item's `screenBuilder` opens a presentation module through its router. Every item carries a `permission` key. | presentation (router) |
| `ApexPermissionChecker` | an adapter over the product's auth/role port | adapter |
| `ApexShellStorage` | `ApexSharedPrefsShellStorage(namespace, tenantId, userId)` or an adapter over the product's storage port | adapter |
| `ApexWorkspaceTab` | dashboards / KPI tabs, each its own presentation module | presentation |

### Menu: pixel-identical to the Apex showcase
- The product menu is **`ApexShell` with `ApexMenuPanel`, used exactly as the Apex showcase app (`apps/apex_showcase`) uses it**, down to the single pixel. That covers:
  - menu buttons (chips);
  - shortcut badges;
  - section containers;
  - gaps, padding, sizes, radii, shadows and fonts;
  - panel width rules;
  - the workspace tabs.
- Never override, wrap, re-pad, re-theme or restyle menu widgets. No custom `Theme`, `MediaQuery` text scaling, `Padding`/`SizedBox` around items, or different icon or label sizes. Pass only menu data: sections, items, shortcuts, permissions.
- **Prove it with a test:** add a golden test that renders the product's menu panel with the same fixture size, theme and fonts as Apex's own menu golden (`packages/apex_app_shell/test/goldens/menu_panel_*.png`). It must match Apex's layout metrics: item rectangles, gaps and padding, compared from widget geometry, so any spacing drift fails the build. Also compare screenshots of the running app's menu against the showcase at the same window size.
- If the menu needs something Apex doesn't offer, add it to Apex; never adjust it in the product.

### Screens
- Every screen is built on `ApexFormScaffold`, using its view states (`ready | loading | error | empty | readOnly`), `isDirty`, `onSave`, `onNew` and validation summary.
- Master-data screens follow Apex's **Master Screen pattern**: `ApexUiListHeader`, `ApexUiDataTable`, `ApexUiPaginationFooter` and `ApexUiMasterFormDialog`, which stays open for continuous entry in create mode. Transactional documents are full-screen `ApexFormScaffold` forms with `ApexFormGrid` / `ApexFieldRow`.
- Feedback goes through `ApexUiNotifier` (toasts) and `ApexUiDialog` (blocking errors, confirmations). Never show a blocking error as a toast.
- Use `context.apexUi*` tokens only. No raw `Color(...)`, magic paddings, `TextStyle(...)` or `fontSize`. User-facing strings support en/ar/es and RTL.

### Fitting Apex into VIPER
Apex's own templates (e.g. the master-screen template) keep state and repository calls inside a `StatefulWidget` for brevity. **Do not copy that structure.** Split it:
- **View:** the Apex widget tree only. It renders presenter state and forwards intents (`onSave` → `presenter.save()`, `onSearch` → `presenter.search(q)`, `onPageChanged` → `presenter.goTo(p)`).
- **Presenter:** owns the screen state (page, filters, dirty flag, validation errors, view state) and calls interactors.
- **Interactors / ports / adapters:** do the loading and saving. Widgets never call repositories or APIs.

Short-lived UI mechanics, such as `TextEditingController`s, `FocusNode`s and the dialog's `isDirty` / `onReset` callbacks, may stay in the widget's `State`. What gets saved and the rules about it may not.

Apex's planned platform packages (`apex_foundation`, `apex_network`, `apex_auth`, `apex_bootstrap`) are not available yet. Until they are, products keep their own ports for HTTP, auth and storage, so adopting those packages later only replaces adapters.

## 3. Folder layout

Always use `package:` imports (enable `always_use_package_imports` in `analysis_options.yaml`), so that the boundary test below can see every dependency.

```
lib/
├── app/                         composition root: MaterialApp + ApexTheme/ApexLocalizations, ApexShell + menu,
│                                ApexPermissionChecker/ApexShellStorage adapters, ProviderScope, environment config
├── core/
│   ├── domain/                  shared kernel: Result/Failure types, common value objects (pure Dart)
│   └── adapters/                shared HTTP client, auth interceptor, storage, error mapping
└── features/
    └── <context>/               one bounded context, e.g. cssd_requests
        ├── <context>.dart       public barrel: the ONLY file other features may import
        ├── domain/
        │   ├── entities/
        │   ├── value_objects/
        │   └── failures/
        ├── application/
        │   ├── ports/           abstract repositories / gateways
        │   └── interactors/     one class per use case
        ├── adapters/
        │   ├── data/            dtos/, api/, repositories/ (port implementations), mappers/
        │   └── di/              Riverpod providers wiring ports to implementations for this context
        └── presentation/
            └── <screen>/
                ├── <screen>_view.dart
                ├── <screen>_presenter.dart
                ├── <screen>_state.dart
                └── <screen>_router.dart
```

## 4. What each layer may import

| Layer | Allowed | Forbidden |
|---|---|---|
| `domain/` | `dart:core`/`dart:collection`/`dart:math`, `package:meta`, `equatable`, `freezed_annotation` (no `fromJson`), `fpdart`/`dartz`, `core/domain` | `package:flutter`, Riverpod, Dio/http, `json_annotation`, storage, `application/`, `adapters/`, `presentation/` |
| `application/` | `domain/`, own `ports/`, `core/domain` | Flutter, Riverpod, Dio/http, JSON, `adapters/`, `presentation/` |
| `presentation/` | `application/` (interactors), `domain/`, Flutter, Riverpod, router package, `adapters/di/` providers | `adapters/data/` (no direct API or DTO use) |
| `adapters/data/` | anything technical, plus `application/ports`, `domain/` | `presentation/` |
| other features | only `features/<other>/<other>.dart` barrel | any other path inside another feature |

## 5. Code shapes

```dart
// domain/value_objects/quantity.dart
final class Quantity {
  Quantity(this.value) {
    if (value < 1 || value > 999) throw ArgumentError.value(value, 'quantity', 'must be 1–999');
  }
  final int value;
  @override bool operator ==(Object o) => o is Quantity && o.value == value;
  @override int get hashCode => value.hashCode;
}

// application/ports/sterilization_request_repository.dart
abstract interface class SterilizationRequestRepository {
  Future<Result<RequestId>> submit(NewSterilizationRequest request);
}

// application/interactors/submit_sterilization_request.dart
final class SubmitSterilizationRequest {
  const SubmitSterilizationRequest(this._repository);
  final SterilizationRequestRepository _repository;

  Future<Result<RequestId>> call(NewSterilizationRequest request) {
    final check = request.validate();          // client-side mirror of backend rules
    return check.isFailure ? Future.value(check.cast()) : _repository.submit(request);
  }
}

// adapters/data/repositories/api_sterilization_request_repository.dart
final class ApiSterilizationRequestRepository implements SterilizationRequestRepository {
  ApiSterilizationRequestRepository(this._api);
  final CssdRequestsApi _api;                    // Dio-based client
  @override
  Future<Result<RequestId>> submit(NewSterilizationRequest r) async { /* DTO mapping + error → Failure */ }
}

// adapters/di/providers.dart (composition root for the context)
final sterilizationRequestRepositoryProvider =
    Provider<SterilizationRequestRepository>((ref) => ApiSterilizationRequestRepository(ref.watch(cssdRequestsApiProvider)));
final submitSterilizationRequestProvider =
    Provider((ref) => SubmitSterilizationRequest(ref.watch(sterilizationRequestRepositoryProvider)));

// presentation/new_request/new_request_presenter.dart
class NewRequestPresenter extends AutoDisposeNotifier<NewRequestState> {
  @override NewRequestState build() => const NewRequestState.initial();
  Future<void> submit() async {
    final result = await ref.read(submitSterilizationRequestProvider)(state.toDomain());
    state = result.fold(NewRequestState.failed, NewRequestState.submitted);
  }
}
```
Views are `ConsumerWidget`s that `watch` presenter state and call presenter methods. They never call interactors, repositories or APIs directly. Tests override the port providers with fakes through `ProviderScope(overrides: [...])`.

## 6. Import-boundary test (mandatory in every Flutter repo)

Put this in `test/architecture/import_boundaries_test.dart`. It needs no extra packages and fails CI on any violation.

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

final _import = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

const _forbidden = <String, List<String>>{
  'domain': ['package:flutter/', 'riverpod', 'package:dio', 'package:http/', 'json_annotation',
             'shared_preferences', '/application/', '/adapters/', '/presentation/'],
  'application': ['package:flutter/', 'riverpod', 'package:dio', 'package:http/', 'json_annotation',
                  '/adapters/', '/presentation/'],
  'presentation': ['package:dio', 'package:http/', '/adapters/data/'],
  'data': ['/presentation/'],
};

Iterable<File> _dartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart') && !f.path.endsWith('.freezed.dart'));

String? _feature(String path) => RegExp(r'features/([a-z0-9_]+)/').firstMatch(path)?.group(1);

void main() {
  test('layers respect the dependency rule and features use public barrels only', () {
    final violations = <String>[];
    for (final file in _dartFiles()) {
      final path = file.uri.pathSegments.join('/');
      final imports = _import.allMatches(file.readAsStringSync()).map((m) => m.group(1)!);
      for (final entry in _forbidden.entries) {
        if (!file.uri.pathSegments.contains(entry.key)) continue;
        for (final imp in imports) {
          for (final bad in entry.value) {
            if (imp.contains(bad)) violations.add('$path (${entry.key}) imports $imp');
          }
        }
      }
      final own = _feature(path);
      for (final imp in imports) {
        final other = _feature(imp);
        if (own != null && other != null && other != own && !imp.endsWith('features/$other/$other.dart')) {
          violations.add('$path reaches into feature "$other" internals: $imp');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
```

### Error-message gate (SKILL.md section 3a)
- **Catalogue:** keep one `ErrorMessageCatalog` per app in core/presentation, keyed by backend `code`. Each entry has `title`, `why`, `nextStep`, an optional `action` and `params` interpolation.
- **Rendering:** render only through the Apex structured error dialog or banner, with severity warning or error and the code/trace in its collapsed Details.
- **Gate test:**
  - It loads the backend's published code registry (a generated JSON/OpenAPI enum, or a shared file) and fails if any code lacks a complete catalogue entry.
  - It scans `lib/` and fails on free-text or deprecated error dialog constructors.
  - Use the Apex gate helpers where available.

## 7. Testing strategy

| Layer | Test type | Tools |
|---|---|---|
| Domain | Pure Dart unit tests for every value object rule and entity behaviour | `test` / `flutter_test` |
| Interactors | Unit tests with fake port implementations | `flutter_test`, hand-written fakes (`mocktail` only for interaction checks) |
| Presenters | State-transition tests using `ProviderContainer` with overridden ports | `flutter_test`, Riverpod overrides |
| Views | Widget tests rendering each state | `flutter_test` |
| Data adapters | DTO mapping and error → Failure mapping tests, HTTP stubbed | `flutter_test`, `http_mock_adapter` or fake client |
| Architecture | Section 6 | built-in test above |
