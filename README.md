# Introduction 
TODO: Give a short introduction of your project. Let this section explain the objectives or the motivation behind this project. 

# Getting Started
TODO: Guide users through getting your code up and running on their own system. In this section you can talk about:
1.	Installation process
2.	Software dependencies
3.	Latest releases
4.	API references

# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Run the backend locally
Prerequisites: JDK 21 and Docker Desktop (running). Commands are for Windows PowerShell, from the repo root.

1. Start PostgreSQL 17 and Mailpit: `docker compose up -d`
   - PostgreSQL on `localhost:5432` (`RESOLVEIT_DB_PORT`), database/user/password `resolveit` (dev only)
   - Mailpit SMTP on `localhost:1025` (`RESOLVEIT_MAILPIT_SMTP_PORT`), web UI at http://localhost:8025
     (`RESOLVEIT_MAILPIT_UI_PORT`); see "Port already in use?" below
2. Start the backend with the `dev` profile: `cd backend; .\mvnw.cmd spring-boot:run`
3. Check it:
   - Health: http://localhost:8080/api/v1/health returns `{"status":"UP"}`
   - OpenAPI JSON: http://localhost:8080/api/docs, Swagger UI: http://localhost:8080/api/docs/ui
4. Stop the database: `docker compose down` (add `-v` to delete its data volume)

Configuration comes only from environment variables: `RESOLVEIT_DB_URL`, `RESOLVEIT_DB_USERNAME`,
`RESOLVEIT_DB_PASSWORD`, `SERVER_PORT` (default 8080). The `dev` profile supplies the local defaults above;
without it, the database variables are required.

**Port already in use?** If 5432, 1025 or 8025 is taken on your machine (for example by a Windows
PostgreSQL service or another project's container), `docker compose` cannot publish the port and the backend
may connect to the wrong PostgreSQL. Pick free host ports and set them as user environment variables
(the defaults stay 5432, 1025 and 8025):

```powershell
[Environment]::SetEnvironmentVariable("RESOLVEIT_DB_PORT", "5440", "User")
[Environment]::SetEnvironmentVariable("RESOLVEIT_MAILPIT_SMTP_PORT", "1026", "User")
[Environment]::SetEnvironmentVariable("RESOLVEIT_MAILPIT_UI_PORT", "8026", "User")
```

Open a new terminal (user variables only reach new processes), then `docker compose down; docker compose up -d`.
`docker-compose.yml` publishes these host ports and the `dev` profile builds its default JDBC URL from
`RESOLVEIT_DB_PORT` (an explicit `RESOLVEIT_DB_URL` still wins). To go back to the defaults, remove a variable
with `[Environment]::SetEnvironmentVariable("RESOLVEIT_DB_PORT", $null, "User")`.

Build and test (unit, integration, ArchUnit, Spring Modulith and error-gate tests; needs Docker for
Testcontainers): `cd backend; .\mvnw.cmd clean verify`. Tests always run with the `test` profile, never `dev`.

Error codes: the registry `ErrorCodeRegistry` is published as `contracts/error-codes.json`. After changing
the registry, regenerate the file with `cd backend; .\mvnw.cmd test "-Dtest=ErrorCodeContractTest" "-DupdateContracts=true"`
and commit it.

# Run the frontend locally
Prerequisites: Flutter stable (3.44 or later) and Chrome. Commands are for Windows PowerShell, from the repo root.

1. Fetch dependencies: `cd frontend; flutter pub get`
2. Start the app on the port the backend's CORS setting expects:
   `flutter run -d chrome --web-port 5000`
   - The shell opens on the Dashboard with the navy side menu. The menu screens are placeholders until their stories arrive.
3. Optional build-time settings (`--dart-define`, no secrets):
   - `API_BASE_URL`: the backend API (default `http://localhost:8080/api/v1`).
   - `DEV_ROLE`: which menu the placeholder user sees: `ADMIN` (default), `SUPPORT_AGENT` (shown as Technician) or
     `EMPLOYEE`. This exists only until login (US-04) is built, and it grants no access.
   - Example: `flutter run -d chrome --web-port 5000 --dart-define=DEV_ROLE=EMPLOYEE`

Checks (from `frontend`):
- `flutter analyze`
- `flutter test`: this includes the import-boundary test, the error-catalogue gate (which reads
  `../contracts/error-codes.json`) and the theme-token test.
- `flutter build web` (output in `frontend/build/web`).

User-facing texts, including the error catalogue, live in `frontend/lib/l10n/app_en.arb`. After changing that file,
run `flutter gen-l10n` and commit the generated files. When the backend adds an error code, add its
`error<Code>Title`, `…Why` and `…NextStep` entries and a line in `ErrorMessageCatalog`; otherwise the catalogue gate
fails.

# UI components
Every screen is built from the shared component library in `frontend/lib/core/presentation/widgets/`
(US-28; deviation D2 – it replaces Apex UI). Import it only through `widgets.dart`. The components use the US-02
theme tokens only and contain no business logic or API calls.

| Group | Components |
|---|---|
| Actions | `AppButton` (primary, secondary, text, danger; icon; loading and disabled states), `AppIconButton` |
| Forms | `AppTextField` (required asterisk, hint, error, counter, password show/hide), `AppDropdown`, `AppSearchField` (300 ms debounce), `AppFormSection` |
| Display | `AppCard`, `StatCard`, `AppChip` (base of `PriorityChip`, `StatusChip`, `RoleChip`, `ActiveChip`), `AvatarInitials` |
| Layout | `PageHeader`, `AppTabs` |
| Data | `AppDataTable` (sortable headers, row action, "Showing x–y of n" pagination; controlled by the presenter) |
| Feedback | `LoadingState`, `EmptyState`, `ErrorPanel` / `showErrorDialog` (errors), `showConfirmDialog`, `AppToast.success` (success only) |

**Component gallery:** in a debug build, open http://localhost:5000/#/dev/components
(`cd frontend; flutter run -d chrome --web-port 5000`). It shows every component in every state. Release builds do
not contain the gallery.

**Guard rule:** `flutter test` fails if a file under `frontend/lib/features/` uses `ElevatedButton`, `TextButton`,
`OutlinedButton`, `FilledButton`, `TextField`, `TextFormField`, `DropdownButton`, `DropdownMenu`, `DataTable`,
`AlertDialog` or `SnackBar` directly; the message names the file and the App component to use instead. A second test
fails on raw colours, `TextStyle`, `fontSize` or numeric paddings inside the library.

# Continuous integration
`azure-pipelines.yml` defines the pipeline **ResolveIT CI** (Azure Pipelines, Microsoft-hosted `ubuntu-latest`,
free tier: 1 parallel job, 1,800 minutes/month).

- **When it runs:** on every push to `development` and `main` (pushes during a run are batched; changes to only
  `README.md`, `CLAUDE.md` or `.claude/` are skipped). Pull requests are validated by a build-validation branch policy
  on `development` (set up by the project admin), not by the YAML. Feature branches do not trigger runs on their own.
- **Backend job:** JDK 21, Maven cache, `./mvnw clean verify` (unit, ArchUnit, Modulith, error-gate and Testcontainers
  integration tests on the agent's Docker), JUnit results published as "Backend".
- **Frontend job:** Flutter installed from the official archive (no Marketplace extension) and cached, then
  `dart format --output=none --set-exit-if-changed .` (first check), `flutter pub get --enforce-lockfile`,
  `flutter analyze`, `flutter test`, `flutter build web --release`, a check that the debug-only component gallery is
  not in the release build, and test results published as "Frontend".
- **Flutter version:** CI uses `FLUTTER_VERSION` / `FLUTTER_SHA256` in `azure-pipelines.yml` and fails if that SDK's
  revision differs from `frontend/.metadata`. When you upgrade Flutter locally, update both variables in the same
  pull request (version and sha256 are listed in
  https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json).
- **Results:** open the run in Azure Pipelines → **Tests** tab (Backend and Frontend runs); a red step's log names the
  failing check.

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)