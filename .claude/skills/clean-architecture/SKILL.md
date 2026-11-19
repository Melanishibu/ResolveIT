---
name: clean-architecture
description: "Mandatory code architecture standard: strict Domain-Driven Design, Hexagonal (ports & adapters) with Clean Architecture layering, and SOLID object-oriented design, with every Flutter screen built from the shared Apex UI package set. Use this skill whenever writing, generating, refactoring, reviewing, scaffolding or planning ANY application code — backend (Java, Spring Boot, Spring Modulith), frontend (Flutter/Dart VIPER, React/TypeScript), or any other language — including new modules, features, bug fixes, user-story implementation, code review, PR review, project setup, screens and UI, and technical design. Apply it even when the user does not mention architecture, DDD, hexagonal or SOLID, and even for small changes."
---

# Clean Architecture Standard

Every piece of application code Claude writes or reviews follows three disciplines at once:

1. **Domain-Driven Design (DDD)** decides *what* the code models: bounded contexts, aggregates, entities, value objects and domain events, all named in the business's own language.
2. **Hexagonal + Clean Architecture** decides *where* code lives and which way dependencies point: the domain in the centre, use cases around it, adapters on the outside.
3. **SOLID** decides *how* each class is shaped.

> Project-specific approved deviations are recorded in the repository's `CLAUDE.md`. Where `CLAUDE.md` lists an approved deviation, follow it; everything else here still applies.

These are organisation-wide rules, not suggestions. The products are long-lived, configured differently for every customer and integrated with many other systems. Code that mixes business rules with frameworks, databases or UI cannot be safely changed, tested or reused across hospitals. That is why this standard exists.

If a request conflicts with a rule here, tell the user which rule it breaks and why it matters, and offer the compliant alternative. Deviate only if the user explicitly approves, and record the deviation (see "Deviations" below).

Stack-specific layouts and enforcement tests are in the reference files. Read the one that matches the code you are touching before writing code:

- Java / Spring Boot / Spring Modulith → `references/java-spring.md`
- Flutter / Dart (VIPER, sVIPER, Riverpod) → `references/flutter.md`, which includes the mandatory use of **Apex UI** for every screen
- Any other language: apply the rules in this file directly, mapping each layer to that language's idiomatic module system.

---

## 1. The dependency rule (the one rule that overrides everything)

Source-code dependencies point **inward only**:

```
  adapters (web, messaging, persistence, external systems, UI, config)
        │  depends on
        ▼
  application (use cases, ports in/out, commands, queries)
        │  depends on
        ▼
  domain (aggregates, entities, value objects, domain events, domain services, policies)
```

- **Domain** depends on nothing but the language's standard library and other domain code of the same bounded context. It has no framework annotations, no ORM, no HTTP, no JSON, no logging framework, no DI container, no Flutter/React imports. A domain class must compile and run in a plain unit test with no container.
- **Application** depends on the domain only, plus a tiny per-stack allowlist that the reference files define (e.g. the transaction annotation in Java). It orchestrates use cases and defines **ports**: the interfaces the outside world calls (inbound) and the interfaces it needs from the outside world (outbound). It knows nothing about how those ports are implemented. Transaction boundaries and authorisation checks belong here.
- **Adapters** depend on application and domain. They implement outbound ports (database, message broker, other HIS modules, printers, devices) and drive inbound ports (REST controllers, event listeners, schedulers, UI presenters). Framework code lives only here and in the composition root.
- **Composition root / configuration** wires implementations to ports. It is the only place allowed to know every concrete class.

Why: business rules are the expensive, long-lived part of a healthcare system. Frameworks, databases and UIs change. Inward dependencies let us test rules in milliseconds, swap an adapter (a new sterilizer interface, a different billing system) without touching the domain, and reuse one domain across hospitals.

## 2. Domain-Driven Design rules

### Strategic design
- **One bounded context = one module** (Spring Modulith module, Dart feature package, etc.) with its own ubiquitous language and, on the backend, its own database schema. Never share tables or entity classes between contexts.
- Contexts talk to each other only through **published contracts**: domain events, or an inbound port / API of the other context. They never use another context's repositories, entities or internal packages.
- When integrating with a legacy or external system (other HIS modules, ERP base platform engines, third-party devices), put an **anti-corruption layer** in an outbound adapter that translates their model into ours. Their names and quirks must not leak into our domain.
- Name everything in the **ubiquitous language** of the domain experts and the ADO work item: `SterilizerLoad.release()`, `Pack.markExpired()`, not `updateStatus(3)` or `LoadManager.process()`. If the spec and the code use different words for the same thing, fix one of them.

### Tactical design
- **Aggregates** are consistency boundaries. Exactly one entity is the aggregate root. Outside code holds references only to the root and refers to other aggregates **by ID**, never by object reference. Load and save the whole aggregate through its repository. One transaction changes one aggregate. Cross-aggregate consistency is eventual, via domain events.
- **Invariants live inside the aggregate.** Every state change goes through an intention-revealing method on the root that validates the rule and then changes state, e.g. `load.start(machineStatus)` throws if the machine is Blocked. No public setters. No business rule may be enforced only in a controller, service, UI or database trigger.
- **Rich, not anaemic.** Behaviour lives with the data it protects. A domain class that is only fields plus getters/setters, with the logic in a "service", is a defect.
- **Value objects** for every domain concept with rules or units: IDs (`PackId`), quantities, money, dates with meaning (`ExpiryDate`), codes, statuses. They are immutable, validated on construction, and compared by value. Avoid primitive obsession: no raw `String`/`int`/`Long` for domain concepts in domain or application signatures.
- **Entities** have identity and a lifecycle. Model their lifecycle as explicit state transitions (`Submitted → Acknowledged → InProcess → Completed`) that reject illegal moves.
- **Domain events** record facts that happened (`PackIssued`, `LoadFailed`), are named in the past tense, are immutable, and are raised by the aggregate. They are published by the application/adapter layer after a successful commit (e.g. a transactional outbox), never from inside a database transaction to a remote system.
- **Domain services** only for domain logic that belongs to no single aggregate. They are stateless and still framework-free.
- **Repositories** are defined as outbound ports in terms of aggregates (`PackRepository.findById(PackId)`, `save(Pack)`), one per aggregate root. Never expose generic CRUD, query builders or ORM types through them.
- **Factories** (static factory methods or factory classes) when creating an aggregate needs non-trivial rules.
- **Policies / specifications** for configurable rules (the products are configured per hospital). A policy is a domain concept with a version and effective date, passed into or looked up by the domain. It is not an `if (hospitalId == 7)` branch.

## 3. Hexagonal + Clean Architecture rules

- **Inbound ports** are use-case interfaces in the application layer, one per use case or per cohesive group (`CreateSterilizationRequestUseCase`, `ReleaseLoadUseCase`). They accept a **command** or **query** object and return a result or read model, never an ORM entity or HTTP type.
- **Use-case implementations** (application services) do only orchestration: load the aggregate through a port, call domain behaviour, save, publish events, map to a result. If a use-case method contains an `if` that encodes a business rule, move that rule into the domain.
- **Outbound ports** are interfaces owned by the application layer, shaped by what the use case needs, not by what the technology offers (`MaintenanceTicketPort.raiseFor(MachineId, Fault)`, not `RestTemplate` wrappers).
- **Adapters** are thin translators. Inbound adapters: validate transport-level input, map DTO → command, call the port, map result → DTO. Outbound adapters: map domain ↔ persistence/external model and call the technology.
- **Keep models separate per layer.** Web DTOs, persistence entities (JPA/ORM rows) and external API models are adapter-layer types, each with explicit mappers. Domain objects are never annotated for, or serialised directly to, JSON or the database.
- **CQRS-lite is allowed for reads.** Queries for screens/reports may bypass aggregates and use a read-model port with a dedicated query adapter, but they must not change state, and they still go through a port.
- **Cross-cutting concerns** (transactions, security, logging, metrics, retries) are applied in the application layer boundary or in adapters, never inside domain objects.
- **User interface:** every Flutter front end uses the shared **Apex UI** package set (the Azure DevOps project *Apex UI UX*) for its application shell, menu, form container, design tokens and widgets. Products consume Apex by pinned version and never copy, fork or re-implement its components. If something is missing (for example a scan field), it is added to Apex, not built in the product. Apex widgets are the *View*: presenters and interactors own state and logic. Details are in `references/flutter.md`.
- **Errors**: the domain throws or returns domain-specific errors (`PackExpiredException`, `Result.failure(...)`), and adapters translate them to transport errors (HTTP 409/422, UI messages). Never leak stack traces, SQL errors or framework exceptions across layers.
- **User-facing error messages** follow section 3a and its CI quality gate.

### 3a. User-facing error and refusal messages (organisation-wide quality gate)

Every message a user sees for a refused action or a failure must let them act without calling support.

- **Format:** every message has three parts.
  - **Title**: what happened ("This set isn't ready for this step").
  - **Why**: the rule, naming the concrete things involved (set, step, station, state): "Set X still needs First wash. Cycles are recorded in process order."
  - **What to do**: the next step, plus an action button where one exists ("Record First wash at DZ-WASH-1, then come back." [Go to First wash]).
  - **Code and trace**: technical details belong to power users and support, so they sit behind a collapsed, grey "Details" link (Apex), never in the main text.
- **Severity:** a business-rule refusal is a *warning* ("Can't do this yet"). A system failure is an *error*. Use the Apex severity styles, not local colours.
- **Transport contract:** backends return RFC 9457 Problem Details with:
  - a stable `code` from one registry per service;
  - `title` and `detail`;
  - `params`: the concrete ids, steps, stations and states the message needs;
  - optional `actions`.
  - Never send free text alone, never send stack traces.
- **Message catalogue:** each front end keeps one catalogue keyed by `code`, with title, why, nextStep and an optional action. Messages interpolate `params`. Unknown codes fall back to a safe generic message plus Details. Screens render messages only through the Apex structured error dialog or banner. Free-text error dialogs are not allowed.
- **Prevent before refusing:** if the screen already knows an action will be refused, disable it and show the reason inline. The dialog is only the safety net.
- **Quality gate (mandatory in every repo's CI, blocks the merge like a failing test):**
  1. **Backend:** a test fails if any error code that is thrown or returned is missing from the registry, or if it lacks the `params` its message needs.
  2. **Front end:** a test fails if any registry code has no catalogue entry, or if an entry lacks title, why or nextStep.
  3. **Front end:** a test or lint fails on any use of a free-text or deprecated error dialog.

  Use the Apex gate helpers where available. If a repo lacks the gate, add it as part of the first change that touches errors, or flag it.

Why: hospital staff at a station cannot decode `STEP_OUT_OF_ORDER`. A refusal that does not say what to do next stops the workflow and generates support calls. Enforcing the format in CI is the only way it stays true across products.

## 4. SOLID rules (applied to every class)

- **S — Single Responsibility:** a class has one reason to change, owned by one actor. Separate the use case, the mapping, the persistence and the presentation. Warning signs: names ending in `Manager`, `Helper`, `Util` or `Processor` that do many things; a class touching both the HTTP request and SQL; more than about 7 injected dependencies.
- **O — Open/Closed:** add new behaviour by adding classes (new policy implementation, new adapter, new strategy), not by editing growing `switch`/`if-else` chains on type codes. Hospital-specific variation is a configured policy or strategy, not a branch.
- **L — Liskov Substitution:** every implementation of a port or subtype honours its contract fully: no `UnsupportedOperationException`, no strengthened preconditions, no surprising side effects. If a subtype can't do everything, the abstraction is wrong. Split it. Prefer composition over inheritance; inheritance only for true "is-a" relationships inside one layer.
- **I — Interface Segregation:** ports are small and client-specific. Prefer `LoadReleasePort` and `LoadQueryPort` over one `LoadService` with 20 methods. No client is forced to depend on methods it doesn't use.
- **D — Dependency Inversion:** high-level policy (domain, application) defines the abstractions; low-level details (adapters) implement them. Depend on interfaces via constructor injection. No `new` of infrastructure inside the domain or application, no service locators, no static access to framework singletons, no field injection.

Additional OO rules that support SOLID:
- Encapsulation first: fields private, immutable by default, no getters that expose mutable internals, *Tell, Don't Ask*.
- Small methods with intention-revealing names. Guard clauses over deep nesting.
- No static mutable state. No "god" base classes. No generic `BaseService<T>` that bypasses the domain.

## 5. How Claude works on a coding task

1. **Read the spec.** The team uses Spec-Anchored Development (see the `safe-agile` skill). Read the ADO user story, its parent feature/epic and acceptance criteria. Note the bounded context/module it names.
2. **Model before coding.** In a short design note (chat or the "Spec check & design" task), state the bounded context, the aggregate(s) and their invariants, value objects, domain events, the use cases (inbound ports), the outbound ports needed, and the adapters. Flag gaps or contradictions in the spec instead of guessing.
3. **Build inside-out:** domain (with unit tests) → application use cases and ports (with tests using fakes/in-memory adapters) → adapters (with integration tests) → wiring/configuration → UI.
4. **Enforce with tests, not only with discipline.** Every module/repo has automated architecture tests (ArchUnit + Spring Modulith `verify()` for Java, an import-boundary test/lint for Dart; see the reference files). If the repo lacks them, add them as part of the first change, or flag it if that's out of scope.
5. **Self-review** the result against the checklist in section 7 before presenting it, and fix violations rather than listing them.
6. **Report** which bounded context, aggregates, ports and adapters were added or changed, plus any deviations.

When **reviewing** code (PRs, existing modules), check it against section 7. Report each violation with file/line, the rule broken, why it matters, and the concrete fix. Rank architecture violations (dependency rule, leaking models, anaemic domain, invariant outside aggregate) above style issues.

## 6. Pragmatism without breaking the rules

- **Strict does not mean ceremonial.** Don't add layers that carry no meaning: no interface for a value object, no mapper between two identical internal types within one layer, no "manager" façade over a single port. Every abstraction must protect a boundary or a variation point.
- **Simple master-data CRUD** still follows the layering (port → use case → repository port → adapter), but the aggregate may legitimately be thin. Keep validation rules in value objects.
- **Legacy / non-compliant code:** don't rewrite unrelated code. New code is compliant. Where new code meets old code, put a port and an adapter (anti-corruption layer) between them. Leave the old code no worse than you found it, and mention the debt in your report.
- **Out of scope:** build scripts, CI pipelines, infrastructure-as-code, database migration scripts, and throwaway spikes clearly marked as such. These still follow SOLID and clear separation where it applies, but they don't need DDD layers. Production code that grew out of a spike must be brought into compliance before merge.

## 7. Review checklist

Dependency rule
- [ ] Domain imports no framework, ORM, web, serialisation, DI, logging-framework or UI packages
- [ ] Application imports domain only (plus its own ports); no adapter or framework types in port signatures
- [ ] Adapters are the only place technology is used; wiring only in configuration/composition root
- [ ] No module reaches into another bounded context's internals, tables or entities

DDD
- [ ] Names match the ubiquitous language of the work item
- [ ] Each aggregate has one root, protects its invariants, references other aggregates by ID
- [ ] No public setters on domain objects; state changes via intention-revealing methods
- [ ] Domain concepts are value objects, not primitives
- [ ] Domain events raised for meaningful facts; published after commit
- [ ] Hospital-specific rules are versioned policies, not branches

Hexagonal / Clean
- [ ] Each use case is exposed through an inbound port with command/query objects
- [ ] Use cases only orchestrate; no business `if` in services, controllers, presenters or widgets
- [ ] Repositories/outbound ports are defined by the application, per aggregate/need
- [ ] DTOs, persistence entities and domain objects are separate types with explicit mapping
- [ ] Domain errors translated to transport errors in adapters
- [ ] User-facing errors follow section 3a (title / why / what to do, details collapsed, Problem Details with code + params) and the error-message quality gate runs in CI
- [ ] Flutter screens use Apex UI (shell, `ApexFormScaffold`, `ApexUi*` widgets, `context.apexUi*` tokens). No local copies or look-alike widgets, no raw colours or `TextStyle`s.

SOLID
- [ ] One responsibility per class; no Manager/Helper/Util grab-bags
- [ ] Variation by new classes (strategy/policy/adapter), not type-switching
- [ ] Implementations honour their port contracts fully
- [ ] Ports are small and client-specific
- [ ] Constructor injection of abstractions; no `new` of infrastructure in inner layers; no static mutable state

Tests
- [ ] Domain unit tests run with no container/framework
- [ ] Use-case tests use fakes/in-memory adapters for outbound ports
- [ ] Adapter integration tests (DB, HTTP, messaging)
- [ ] Architecture tests present and passing

## 8. Deviations

If the user explicitly approves breaking a rule (e.g. a performance-critical query that must cross a boundary):
- Keep the deviation as small and isolated as possible, inside an adapter where you can.
- Mark it in code with a comment beginning `ARCH-DEVIATION:` stating the rule, the reason, the approver, and the ADO item (`AB#<id>`).
- Mention it in the PR description so the human reviewer signs it off.
- Never deviate on the dependency rule for the domain layer. Domain purity is non-negotiable, because every other guarantee depends on it.
