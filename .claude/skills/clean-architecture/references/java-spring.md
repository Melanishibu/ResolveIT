# Java / Spring Boot / Spring Modulith

How the clean architecture standard maps onto Java backends (Spring Boot 4.x, Spring Modulith 2.x, PostgreSQL). If a repository already has an equivalent layout that satisfies the dependency rule, keep its naming rather than restructuring it. Otherwise use this one.

## Contents
1. Package layout
2. What each layer may import
3. Code shapes (aggregate, value object, port, use case, adapters, wiring)
4. Events between bounded contexts
5. Architecture tests (mandatory)
6. Testing strategy

## 1. Package layout

One Spring Modulith application module = one bounded context = one PostgreSQL schema.

```
com.<company>.<product>.<app>                      ← @SpringBootApplication (e.g. com.example.erp.cssd)
└── <context>                                      ← Modulith module, e.g. requests, loads, inventory
    ├── <Context>Api.java                          ← published API: interface other modules may call
    ├── <Something>Event.java                      ← published integration events (plain records)
    ├── domain
    │   ├── model        aggregates, entities, value objects, enums of the ubiquitous language
    │   ├── event        domain events (internal to the context)
    │   ├── policy       configurable policies / specifications
    │   └── service      domain services (only if logic fits no aggregate)
    ├── application
    │   ├── port
    │   │   ├── in       use-case interfaces + Command / Query / Result records
    │   │   └── out      repository ports, external-system ports, event-publisher port
    │   └── service      use-case implementations (orchestration only)
    ├── adapters
    │   ├── in
    │   │   ├── web        REST controllers, request/response DTOs, DTO mappers, exception → HTTP mapping
    │   │   ├── messaging  event listeners for other modules' integration events
    │   │   └── scheduler  scheduled jobs that call inbound ports
    │   └── out
    │       ├── persistence  JPA entities, Spring Data repositories, mappers, port implementations
    │       └── integration  anti-corruption adapters to other HIS/ERP modules, devices, printers
    └── config            @Configuration classes: the composition root for this module
```

Spring Modulith treats the module's base package as its public API and every sub-package as internal. Other modules may use only `<Context>Api` and the published event records. Everything under `domain`, `application`, `adapters` and `config` is private to the context.

## 2. What each layer may import

| Layer | Allowed | Forbidden |
|---|---|---|
| `domain..` | `java.*`, same-context `domain..` | Spring, Jakarta (JPA, validation, inject), Hibernate, Jackson, SLF4J/logging, Lombok `@Data`/`@Setter`, `application..`, `adapters..`, other contexts |
| `application..` | `domain..`, own ports, `org.springframework.transaction.annotation.Transactional`, `org.slf4j` | Spring Web/Data/JPA, Jakarta Persistence, Jackson, `adapters..`, other contexts' internals |
| `adapters..` | anything needed for its technology, plus `application..` and `domain..` | other adapters' internals (web must not call persistence directly), other contexts' internals |
| `config` | everything in its own context | business logic of any kind |

`@Transactional` is the only Spring annotation allowed in application services, because the transaction boundary *is* the use-case boundary. Application services are **not** annotated `@Service`/`@Component`. They are plain classes registered as `@Bean`s in `config`, which keeps the application layer framework-free apart from the transaction annotation.

Lombok: `@Getter`, `@RequiredArgsConstructor` and `@Builder` are tolerated in adapters. In the domain, prefer Java records for value objects and hand-written constructors and methods for entities, because `@Setter`/`@Data` break encapsulation.

## 3. Code shapes

### Value object
```java
package com.example.erp.cssd.requests.domain.model;

public record Quantity(int value) {
    public Quantity {
        if (value < 1 || value > 999) throw new InvalidQuantityException(value);
    }
}
```

### Aggregate root
```java
package com.example.erp.cssd.requests.domain.model;

public class SterilizationRequest {
    private final RequestId id;
    private final LocationId sender;
    private final List<RequestLine> lines;
    private RequestStatus status;
    private final List<Object> domainEvents = new ArrayList<>();

    private SterilizationRequest(RequestId id, LocationId sender, List<RequestLine> lines, CaseType caseType) {
        if (lines.isEmpty()) throw new EmptyRequestException();
        this.id = id; this.sender = sender; this.lines = List.copyOf(lines);
        this.status = RequestStatus.SUBMITTED;
        domainEvents.add(new SterilizationRequested(id, sender, caseType));
    }

    public static SterilizationRequest submit(RequestId id, LocationId sender,
                                              List<RequestLine> lines, CaseType caseType,
                                              FirstWashRule firstWashRule) {
        firstWashRule.verify(lines);                 // policy enforces "first wash done for OT sets"
        return new SterilizationRequest(id, sender, lines, caseType);
    }

    public void cancel() {
        if (status != RequestStatus.SUBMITTED) throw new IllegalRequestTransitionException(status, RequestStatus.CANCELLED);
        status = RequestStatus.CANCELLED;
        domainEvents.add(new SterilizationRequestCancelled(id));
    }

    public List<Object> pullDomainEvents() { var e = List.copyOf(domainEvents); domainEvents.clear(); return e; }
    public RequestId id() { return id; }
    public RequestStatus status() { return status; }
}
```
No setters, invariants checked in the constructor and in each transition, events collected by the aggregate.

### Inbound port + command
```java
package com.example.erp.cssd.requests.application.port.in;

public interface SubmitSterilizationRequestUseCase {
    RequestId submit(SubmitRequestCommand command);
}

public record SubmitRequestCommand(LocationId sender, List<RequestLineCommand> lines, CaseType caseType, boolean firstWashDone) {}
```

### Outbound ports
```java
package com.example.erp.cssd.requests.application.port.out;

public interface SterilizationRequestRepository {      // one per aggregate root, aggregate-shaped
    Optional<SterilizationRequest> findById(RequestId id);
    void save(SterilizationRequest request);
    RequestId nextId();
}

public interface DomainEventPublisher { void publish(List<Object> events); }
public interface RoutePolicyPort { FirstWashRule firstWashRuleFor(LocationId sender); }
```

### Use case (orchestration only)
```java
package com.example.erp.cssd.requests.application.service;

public class SubmitSterilizationRequestService implements SubmitSterilizationRequestUseCase {
    private final SterilizationRequestRepository requests;
    private final RoutePolicyPort routePolicy;
    private final DomainEventPublisher events;

    public SubmitSterilizationRequestService(SterilizationRequestRepository requests,
                                             RoutePolicyPort routePolicy, DomainEventPublisher events) {
        this.requests = requests; this.routePolicy = routePolicy; this.events = events;
    }

    @Transactional
    @Override
    public RequestId submit(SubmitRequestCommand cmd) {
        var request = SterilizationRequest.submit(requests.nextId(), cmd.sender(),
                RequestLineMapper.toDomain(cmd.lines()), cmd.caseType(),
                routePolicy.firstWashRuleFor(cmd.sender()));
        requests.save(request);
        events.publish(request.pullDomainEvents());
        return request.id();
    }
}
```

### Inbound web adapter
```java
package com.example.erp.cssd.requests.adapters.in.web;

@RestController
@RequestMapping("/api/cssd/requests")
class SterilizationRequestController {
    private final SubmitSterilizationRequestUseCase submit;
    SterilizationRequestController(SubmitSterilizationRequestUseCase submit) { this.submit = submit; }

    @PostMapping
    ResponseEntity<SubmitRequestResponse> submit(@Valid @RequestBody SubmitRequestDto dto) {
        RequestId id = submit.submit(SubmitRequestDtoMapper.toCommand(dto));
        return ResponseEntity.status(HttpStatus.CREATED).body(new SubmitRequestResponse(id.value()));
    }
}
```
Bean Validation (`@Valid`) checks transport shape only (required fields, formats). Business rules stay in the domain. A `@RestControllerAdvice` in `adapters.in.web` maps domain exceptions to HTTP status codes (422 for rule violations, 409 for illegal transitions, 404 for not found).

### Outbound persistence adapter
```java
package com.example.erp.cssd.requests.adapters.out.persistence;

@Entity @Table(schema = "cssd_requests", name = "sterilization_request")
class SterilizationRequestJpaEntity { /* columns, JPA-only concerns */ }

interface SterilizationRequestJpaRepository extends JpaRepository<SterilizationRequestJpaEntity, UUID> {}

class JpaSterilizationRequestRepository implements SterilizationRequestRepository {
    private final SterilizationRequestJpaRepository jpa;
    private final SterilizationRequestPersistenceMapper mapper;
    // findById → jpa.findById(...).map(mapper::toDomain); save → jpa.save(mapper.toEntity(request))
}
```
JPA entities never leave this package. Mappers rebuild aggregates through a package-private or explicit `reconstitute(...)` factory that skips creation-time events.

### Composition root
```java
package com.example.erp.cssd.requests.config;

@Configuration
class RequestsModuleConfig {
    @Bean SubmitSterilizationRequestUseCase submitSterilizationRequest(
            SterilizationRequestRepository repo, RoutePolicyPort policy, DomainEventPublisher events) {
        return new SubmitSterilizationRequestService(repo, policy, events);
    }
    @Bean SterilizationRequestRepository sterilizationRequestRepository(
            SterilizationRequestJpaRepository jpa, SterilizationRequestPersistenceMapper mapper) {
        return new JpaSterilizationRequestRepository(jpa, mapper);
    }
}
```

## 4. Events between bounded contexts

- The aggregate raises **domain events** (`domain.event`, internal).
- The `DomainEventPublisher` adapter publishes them through Spring's `ApplicationEventPublisher`. Enable Spring Modulith's **event publication registry** (JPA/JDBC) so publication is recorded in the same transaction. This works as a transactional outbox, giving at-least-once delivery after commit.
- Where another context needs to know, an adapter maps the domain event to a **published integration event** (a record in the module's base package) that carries IDs and facts, not entities.
- Consumers listen in `adapters.in.messaging` with `@ApplicationModuleListener` and call their own inbound port. Listeners are idempotent.
- To leave the JVM (Kafka/RabbitMQ to other HIS services), use Spring Modulith event externalisation or an outbound messaging adapter. Never publish to a broker inside the DB transaction.

## 5. Architecture tests (mandatory in every backend repo)

Dependencies: `com.tngtech.archunit:archunit-junit5` and `org.springframework.modulith:spring-modulith-starter-test`.

```java
@AnalyzeClasses(packages = "com.example.erp.cssd", importOptions = ImportOption.DoNotIncludeTests.class)
class CleanArchitectureTest {

    @ArchTest
    static final ArchRule domain_is_framework_free = noClasses()
            .that().resideInAPackage("..domain..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    "org.springframework..", "jakarta..", "javax..", "org.hibernate..",
                    "com.fasterxml..", "org.slf4j..", "lombok..",
                    "..application..", "..adapters..", "..config..");

    @ArchTest
    static final ArchRule application_has_no_technology = noClasses()
            .that().resideInAPackage("..application..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    "..adapters..", "..config..", "org.springframework.web..", "org.springframework.data..",
                    "org.springframework.stereotype..", "jakarta.persistence..", "org.hibernate..", "com.fasterxml..");

    @ArchTest
    static final ArchRule onion = onionArchitecture()
            .domainModels("..domain.model..", "..domain.event..", "..domain.policy..")
            .domainServices("..domain.service..")
            .applicationServices("..application..")
            .adapter("web", "..adapters.in.web..")
            .adapter("messaging", "..adapters.in.messaging..")
            .adapter("scheduler", "..adapters.in.scheduler..")
            .adapter("persistence", "..adapters.out.persistence..")
            .adapter("integration", "..adapters.out.integration..");

    @ArchTest
    static final ArchRule no_field_injection = GeneralCodingRules.NO_CLASSES_SHOULD_USE_FIELD_INJECTION;

    @ArchTest
    static final ArchRule jpa_entities_stay_in_persistence = classes()
            .that().areAnnotatedWith(jakarta.persistence.Entity.class)
            .should().resideInAPackage("..adapters.out.persistence..");

    @ArchTest
    static final ArchRule controllers_stay_in_web = classes()
            .that().areAnnotatedWith(org.springframework.web.bind.annotation.RestController.class)
            .should().resideInAPackage("..adapters.in.web..");
}

class ModularityTest {
    @Test
    void bounded_contexts_respect_module_boundaries() {
        ApplicationModules.of(CssdApplication.class).verify();   // no cycles, no access to other modules' internals
    }
}
```
These tests run in CI on every PR. A failing architecture test blocks the merge just like a failing unit test does.

### Error-message gate (SKILL.md section 3a)
- **One `ErrorCode` registry per service:** an enum or a sealed type that declares each code's required `params`.
- **Domain errors carry their code:** each domain error carries its `ErrorCode` and params.
- **Problem Details in the web adapter:** a `@RestControllerAdvice` maps domain errors to RFC 9457 Problem Details (`ProblemDetail` with properties `code`, `params`, `actions`).
- **Gate test:**
  - It scans the domain error types, or every `throw` site through ArchUnit, and asserts that each one uses a registry code and supplies that code's required params.
  - It also asserts that no controller returns a bare string or exception message as an error body.

## 6. Testing strategy

| Layer | Test type | Tools |
|---|---|---|
| Domain | Pure unit tests, no Spring context, one test class per aggregate/value object, cover every invariant and transition | JUnit 5, AssertJ |
| Application | Use-case tests with in-memory fakes for outbound ports (prefer hand-written fakes over mocks for repositories) | JUnit 5, AssertJ, Mockito only for interaction-only ports |
| Adapters in | Web slice tests: DTO mapping, validation, error → HTTP mapping | `@WebMvcTest`, MockMvc |
| Adapters out | Persistence/integration tests against real PostgreSQL | Testcontainers, `@DataJpaTest` |
| Module | Module integration and event flow | `@ApplicationModuleTest`, `Scenario` API |
| Architecture | Section 5 | ArchUnit, Spring Modulith |

Acceptance criteria from the ADO story (Gherkin) map to use-case or module tests named after each scenario.
