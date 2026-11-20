# ResolveIT – Rules for Claude Code

## Project
ResolveIT is an IT Service Desk and Incident Management application: incidents, assignments,
priorities, status updates, comments and resolution history.

- `backend/` – Spring Boot 4.x + Spring Modulith 2.x REST API, Java 21, Maven wrapper (`mvnw`).
  Base package `com.itsm.resolveit`. One Modulith module = one bounded context = one PostgreSQL schema.
- `frontend/` – Flutter app (web target), VIPER + Riverpod. See deviation D2 for the UI kit.
- `docker-compose.yml` – PostgreSQL for local development only. Persistence tests use Testcontainers
  (Docker Desktop must be running).
- If `backend/` or `frontend/` does not exist yet, only the scaffolding story creates it.

## Standards (skills in `.claude/skills/` – always apply)
- `safe-agile` – PIs, iterations, PODs, capacity, work item hierarchy, mandatory content, tags,
  batch tags, Bug vs Issue, states while executing (section 8a).
- `clean-architecture` (+ `references/java-spring.md`, `references/flutter.md`) – DDD, hexagonal /
  clean layering, SOLID, error-message quality gate, architecture tests.

Read the relevant skill before planning or writing code. If this file and a skill disagree, this file
wins only where it lists an approved deviation below; otherwise the skill wins.

## Azure DevOps (verified 11/19/2026)
- Organization `MelaniDevops`, project `ResolveIT` (Agile process), repo `ResolveIT`,
  default branch `development`. Use the `azure-devops` MCP server for all work item, branch and
  pull request actions.
- ART-level team: **ResolveIT Team** – area `ResolveIT` (sub-areas included), iterations include
  the PI node `ResolveIT\PI_01`.
- POD team: **POD 1** (Melani Shibu + Claude) – area `ResolveIT\POD 1`.
- PI_01: 11/19/2026 – 1/27/2027
  - Iteration 1.1: 11/19/2026 – 12/2/2026
  - Iteration 1.2: 12/3/2026 – 12/16/2026
  - Iteration 1.3: 12/17/2026 – 12/30/2026 (holiday 12/25/2026)
  - Iteration 1.4: 12/31/2026 – 1/13/2027
  - Iteration 1.5: 1/14/2027 – 1/27/2027 (holiday 1/26/2027)
- Holidays are recorded as POD 1 team days off. Melani's capacity: 6 h/day, Development.
- Placement: Epics and Features → area `ResolveIT`, iteration `ResolveIT\PI_01`.
  Stories and Tasks → area `ResolveIT\POD 1`, iteration `ResolveIT\PI_01\Iteration x.y`.
- Tags: `POD-1` on Stories and Tasks, `spec-anchored` on every item, `batch-YYYYMMDD-NN` on every
  newly created item, `claude` or `human` on Tasks.
- Never ask for, read or print the `PERSONAL_ACCESS_TOKEN` environment variable. The PAT has only the
  scopes it needs. If a call fails with 401/403, stop and tell me which scope seems missing; never
  suggest Full access.

## Approved deviations
- **D1 – Sprint length: 2 weeks** (standard: 1 week). Approved by Melani Shibu on 11/19/2026.
  Sprints still start on Thursday and end on Wednesday, 5 iterations per PI.
  Capacity per POD per iteration: 10 working days × 12 SP = **120 SP total, at most 96 SP committed**,
  minus 12 SP per lost day (Iterations 1.3 and 1.5: 108 total / 84 committed).
- **D2 – No Apex UI** (no access to the Apex UI UX project). Approved by Melani Shibu on 11/19/2026.
  Flutter screens use plain Material widgets. Everything else in `references/flutter.md` still applies:
  VIPER layers, Riverpod, `package:` imports, the import-boundary test, the error-message catalogue and
  gate, and no raw colours / `TextStyle` / magic paddings outside one app theme in `lib/app/theme/`.
  Build one structured error dialog/banner widget in `lib/core/presentation/` (title, why, next step,
  collapsed Details) and use only that. Skip the Apex menu golden test. Mark the composition root
  (`lib/app/app.dart`) with `// ARCH-DEVIATION: D2 – no Apex UI access; Material widgets; approved by
  Melani Shibu 11/19/2026`, and mention D2 in PR descriptions that add screens.

## Frontend feature layout
Approved by Melani Shibu on 11/21/2026 (RIT-US-29, AB#175). It replaces the earlier folder layout, within the
`references/flutter.md` rule that a project may use its own VIPER names if the dependency rule holds. Enforced by
`frontend/test/architecture/import_boundary_checker.dart` (deliberately broken samples live under `test/` only).

```
lib/features/<feature>/
  data/datasource/        REST calls via Dio, data models
  data/repository/        implementations of domain/repository
  domain/entity/          entities and value objects, pure Dart
  domain/repository/      abstract repository contracts
  domain/usecase/         one business operation per class
  interactor/             coordinates use cases for a presentation flow, pure Dart
  presentation/presenter/ Riverpod notifiers holding screen state, calling the interactor
  presentation/router/    the feature's routes
  presentation/view/      widgets only, render presenter state
  widgets/                feature-specific widgets built on core/presentation/widgets
  providers.dart          the feature's dependency wiring
  <feature>.dart          public barrel; other features import only this
```

| Folder | Must never import |
|---|---|
| `data/datasource`, `data/repository` | `presentation`, `interactor` |
| `domain/entity`, `domain/repository`, `domain/usecase` | Flutter, Riverpod, Dio/HTTP, browser APIs, l10n, `core/adapters`, JSON, `data`, `interactor`, `presentation` |
| `interactor` | Flutter, Riverpod, Dio/HTTP, browser APIs, l10n, `core/adapters`, `data`, `presentation` |
| `presentation/presenter` | `data`, Dio/HTTP, `core/adapters`, `domain/usecase`, `domain/repository` |
| `presentation/router` | `data`, Dio/HTTP, `core/adapters` |
| `presentation/view` | `data`, Dio/HTTP, `core/adapters`, `interactor`, `domain/usecase` |
| `widgets` | `data`, Dio/HTTP, `core/adapters`, `interactor` |
| `providers.dart` | – (anything in its own feature) |
| another feature's files | everything except that feature's `<feature>.dart` |

Features: `auth` (login, logout, current user, set/forgot/change password), `users` (user management, My Profile),
`dashboard`, `incident` (create, list, details, search, history, status), `assignment`, `comments`. Create only the
folders a feature needs. Types shared by several features without UI (for example `Role`) live in `lib/core/domain/`.

## Workflow for every story
1. **Read** the story, its Acceptance Criteria, child Tasks, parent Feature and Epic, and linked
   predecessors. If the spec has gaps or contradictions, post a question as a work item comment and stop.
2. **Plan**: post a Plan comment on the story (template below), including the design note from the
   `clean-architecture` skill. Then STOP and wait for my explicit approval in this chat.
3. **Start**: set the story Active (and its Feature/Epic Active if still New) and set each Task Active
   when you start it, with a short evidence comment on every state change.
4. **Branch** from the latest `origin/development`: `feature/<story id>-<short-name>`
   (lowercase, hyphens), for example `feature/123-report-incident`.
5. **Build inside-out** (domain → application → adapters → wiring → UI). At least one automated test
   per Gherkin scenario, named after the scenario.
6. **Verify**: run the full build and tests (see Commands). Everything must be green, including the
   architecture tests.
7. **Commit** with messages like `AB#123 Add report-incident use case`. Push the feature branch and
   **open a pull request into `development`**, linked to the story.
8. **Evidence**: post an Evidence comment on the story (template below).
9. **States after the PR**: the story stays **Active** (work is not merged to `main` yet). Tasks stay
   Active unless I have authorised you to close them. List what awaits me in the Evidence comment.

## Hard rules (never break these)
- Never push to, commit directly on, or merge into `main` or `development`. Never force-push.
  Never delete remote branches. Never approve or complete a pull request.
- Never set a story to Resolved or Closed, and never close a Task, unless I have explicitly
  authorised it in this chat. If authorised, write: "Closed by Claude under Melani Shibu's
  authorisation of <date>; evidence: …".
- Existing tests must not be modified, deleted, skipped (`@Disabled`, `skip`) or weakened unless the
  story explicitly changes that behaviour. If it does, say so in the Plan and Evidence comments.
- No secrets in code, config, logs, commits, comments or PR descriptions. Dev defaults only (local
  Docker PostgreSQL user `resolveit` / password `resolveit`). Real config comes from environment
  variables.
- Stay within the story's scope. Log other problems as Bugs or Issues (per `safe-agile`) or list
  them as follow-ups; don't fix them unasked.
- PR descriptions stay short (Azure DevOps limit: 4000 characters): summary, linked story, how it was
  tested, any `ARCH-DEVIATION`.

## Commands (Windows PowerShell, from the repo root)
Database:
- Start: `docker compose up -d`
- Stop: `docker compose down`

Backend (`cd backend`):
- Build and test (incl. ArchUnit + Modulith tests): `.\mvnw.cmd clean verify`
- Run: `.\mvnw.cmd spring-boot:run`

Frontend (`cd frontend`):
- Dependencies: `flutter pub get`
- Static checks: `flutter analyze`
- Tests (incl. import-boundary test): `flutter test`
- Run: `flutter run -d chrome`
- Build: `flutter build web`

"Green" means `.\mvnw.cmd clean verify` passes, `flutter analyze` reports no errors, and
`flutter test` passes.

## Comment templates
**Plan – AB#<id> <title>**
- Bounded context, aggregate(s) and invariants, value objects, domain events
- Use cases (inbound ports), outbound ports, adapters
- Files to add/change
- Tests: one line per Gherkin scenario → the test that covers it
- Database changes (schema, migrations), if any
- Questions or risks

**Evidence – AB#<id> <title>**
- What was built: 2–5 bullets
- Gherkin scenario → test → result (pass/fail)
- Commands run and results (for example "mvnw clean verify: 24 tests, 0 failures")
- Branch, commit SHA(s), pull request link
- State changes made, and what awaits Melani
- Follow-ups (out of scope)
