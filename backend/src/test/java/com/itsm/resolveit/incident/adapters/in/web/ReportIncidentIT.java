package com.itsm.resolveit.incident.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.ActorRole;
import com.itsm.resolveit.incident.application.port.in.ReportIncidentCommand;
import com.itsm.resolveit.incident.application.port.out.IncidentAuditLog;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.application.port.out.TicketNumberGenerator;
import com.itsm.resolveit.incident.application.service.ReportIncidentService;
import com.itsm.resolveit.incident.domain.model.Category;
import com.itsm.resolveit.incident.domain.model.Description;
import com.itsm.resolveit.incident.domain.model.Priority;
import com.itsm.resolveit.incident.domain.model.Title;
import com.itsm.resolveit.testsupport.AuthApiClient;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Role;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Session;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Clock;
import java.time.Instant;
import java.time.Year;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.TestPropertySource;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/** RIT-US-09 (AB#37) backend Gherkin scenarios over real HTTP and a real PostgreSQL. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class ReportIncidentIT {

    private static final String EMPLOYEE_ONE = "00000000-0000-4000-8000-000000000004";
    private static final String TICKET_FORMAT = "INC-\\d{4}-\\d{5}";
    private static final JsonMapper JSON = JsonMapper.builder().build();

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    @Autowired
    private TicketNumberGenerator ticketNumbers;

    @Autowired
    private IncidentRepository incidents;

    @Autowired
    private IncidentAuditLog auditLog;

    // Scenario: TC-003 Employee creates an incident
    @Test
    void tc003EmployeeCreatesAnIncident() throws Exception {
        Session employee = matrix().logIn(Role.EMPLOYEE);
        int year = Year.now(ZoneOffset.UTC).getValue();

        HttpResponse<String> response = report(employee, Map.of("title", "Laptop won't start",
                "description", "The power LED blinks and the screen stays black.", "category", "HARDWARE",
                "priority", "HIGH"));

        assertThat(response.statusCode()).isEqualTo(201);
        JsonNode created = json(response);
        assertThat(created.get("status").asString()).isEqualTo("OPEN");
        assertThat(created.get("ticketNumber").asString()).matches("INC-" + year + "-\\d{5}");
        assertThat(created.get("title").asString()).isEqualTo("Laptop won't start");
        assertThat(created.get("category").asString()).isEqualTo("HARDWARE");
        assertThat(created.get("priority").asString()).isEqualTo("HIGH");
        assertThat(created.get("createdBy").asString()).as("the creator is that Employee").isEqualTo(EMPLOYEE_ONE);
        assertThat(created.get("createdAt").asString()).endsWith("Z");

        List<Map<String, Object>> audit = jdbc.sql("""
                SELECT action, actor_id::text AS actor, new_value FROM incident.incident_audit_log
                WHERE incident_id = :id::uuid""").param("id", created.get("id").asString()).query().listOfRows();
        assertThat(audit).singleElement().satisfies(entry -> {
            assertThat(entry.get("action")).isEqualTo("CREATED");
            assertThat(entry.get("actor")).isEqualTo(EMPLOYEE_ONE);
            assertThat((String) entry.get("new_value")).contains(created.get("ticketNumber").asString())
                    .contains("HIGH").contains("HARDWARE");
        });
    }

    // Scenario: TC-004 Empty title is rejected
    @Test
    void tc004EmptyTitleIsRejected() throws Exception {
        HttpResponse<String> response = report(matrix().logIn(Role.EMPLOYEE), Map.of("title", "",
                "description", "Something broke", "category", "SOFTWARE", "priority", "LOW"));

        assertThat(response.statusCode()).isEqualTo(400);
        JsonNode problem = json(response);
        assertThat(problem.get("code").asString()).isEqualTo("VALIDATION_FAILED");
        assertThat(problem.get("params").get("fields").toString()).isEqualTo("[\"title\"]");
    }

    // Scenario: Field limits are enforced
    @Test
    void fieldLimitsAreEnforced() throws Exception {
        Session employee = matrix().logIn(Role.EMPLOYEE);

        HttpResponse<String> longTitle = report(employee, Map.of("title", "t".repeat(121),
                "description", "ok", "category", "NETWORK", "priority", "MEDIUM"));
        HttpResponse<String> longDescription = report(employee, Map.of("title", "ok",
                "description", "d".repeat(2001), "category", "NETWORK", "priority", "MEDIUM"));

        assertThat(longTitle.statusCode()).isEqualTo(400);
        assertThat(json(longTitle).get("code").asString()).isEqualTo("VALIDATION_FAILED");
        assertThat(json(longTitle).get("params").get("fields").toString()).isEqualTo("[\"title\"]");
        assertThat(longDescription.statusCode()).isEqualTo(400);
        assertThat(json(longDescription).get("code").asString()).isEqualTo("VALIDATION_FAILED");
        assertThat(json(longDescription).get("params").get("fields").toString()).isEqualTo("[\"description\"]");
        assertThat(report(employee, Map.of("title", "t".repeat(120), "description", "d".repeat(2000),
                "category", "NETWORK", "priority", "MEDIUM")).statusCode()).as("at the limits").isEqualTo(201);
        assertThat(report(employee, Map.of("title", "  " + "t".repeat(120) + "  ", "description", "ok",
                "category", "NETWORK", "priority", "MEDIUM")).statusCode()).as("limits apply after trimming").isEqualTo(201);
    }

    // Scenario: Ticket numbers stay unique under concurrent requests
    @Test
    void ticketNumbersStayUniqueUnderConcurrentRequests() throws Exception {
        Session employee = matrix().logIn(Role.EMPLOYEE);
        int parallel = 50;
        CountDownLatch start = new CountDownLatch(1);
        List<Callable<HttpResponse<String>>> calls = new ArrayList<>();
        for (int i = 0; i < parallel; i++) {
            int n = i;
            calls.add(() -> {
                start.await();
                return report(employee, Map.of("title", "Concurrent " + n, "description", "Load test",
                        "category", "OTHER", "priority", "LOW"));
            });
        }

        List<String> numbers = new ArrayList<>();
        try (ExecutorService pool = Executors.newFixedThreadPool(parallel)) {
            List<Future<HttpResponse<String>>> futures = new ArrayList<>();
            for (Callable<HttpResponse<String>> call : calls) {
                futures.add(pool.submit(call));
            }
            start.countDown();
            for (Future<HttpResponse<String>> future : futures) {
                HttpResponse<String> response = future.get();
                assertThat(response.statusCode()).as(response.body()).isEqualTo(201);
                numbers.add(json(response).get("ticketNumber").asString());
            }
        }

        Set<String> distinct = new HashSet<>(numbers);
        assertThat(distinct).as("all 50 ticket numbers are different").hasSize(parallel);
        assertThat(numbers).allMatch(number -> number.matches(TICKET_FORMAT));
    }

    // Scenario: Support Agent cannot create incidents
    @Test
    void supportAgentCannotCreateIncidents() throws Exception {
        Map<String, String> valid = Map.of("title", "Agent ticket", "description", "Should be refused",
                "category", "ACCESS", "priority", "LOW");

        HttpResponse<String> agent = report(matrix().logIn(Role.SUPPORT_AGENT), valid);

        assertThat(agent.statusCode()).isEqualTo(403);
        assertThat(json(agent).get("code").asString()).isEqualTo("AUTH_FORBIDDEN");
        assertThat(report(matrix().logIn(Role.ADMIN), valid).statusCode()).as("Admin may").isEqualTo(201);
        assertThat(report(null, valid).statusCode()).as("anonymous").isEqualTo(401);
        assertThat(jdbc.sql("SELECT count(*) FROM incident.incident WHERE title = 'Agent ticket'")
                .query(Integer.class).single()).as("only the Admin's incident exists").isEqualTo(1);
    }

    // Scenario: Audit entries cannot be changed
    @Test
    void auditEntriesCannotBeChanged() throws Exception {
        String id = json(report(matrix().logIn(Role.EMPLOYEE), Map.of("title", "Audited", "description", "x",
                "category", "SOFTWARE", "priority", "LOW"))).get("id").asString();

        assertThatThrownBy(() -> jdbc.sql("UPDATE incident.incident_audit_log SET action = 'X' WHERE incident_id = :id::uuid")
                .param("id", id).update()).isInstanceOf(DataAccessException.class);
        assertThatThrownBy(() -> jdbc.sql("DELETE FROM incident.incident_audit_log WHERE incident_id = :id::uuid")
                .param("id", id).update()).isInstanceOf(DataAccessException.class);
        assertThatThrownBy(() -> jdbc.sql("TRUNCATE incident.incident_audit_log CASCADE").update())
                .isInstanceOf(DataAccessException.class);
        assertThat(jdbc.sql("SELECT count(*) FROM incident.incident_audit_log WHERE incident_id = :id::uuid")
                .param("id", id).query(Integer.class).single()).isEqualTo(1);
    }

    // Scenario: Ticket counter restarts each year
    @Test
    void ticketCounterRestartsEachYear() {
        // The scenario's 2026/2027 shifted to 2098/2099: years no other test (or real run) touches, so the
        // test stays correct when the suite itself runs in 2027 (review finding 1 on !11).
        // Given the last incident of 2098 is INC-2098-00418.
        jdbc.sql("""
                INSERT INTO incident.ticket_counter (year, last_number) VALUES (2098, 418)
                ON CONFLICT (year) DO UPDATE SET last_number = 418
                """).update();
        jdbc.sql("DELETE FROM incident.ticket_counter WHERE year = 2099").update();
        Actor employee = new Actor(UUID.fromString(EMPLOYEE_ONE), ActorRole.EMPLOYEE);
        ReportIncidentCommand command = new ReportIncidentCommand(employee, new Title("Year boundary"),
                new Description("Reported around New Year"), Category.OTHER, Priority.LOW);

        // When the first incident of 2099 is created (one second after the year starts, UTC)
        String lastOf2098 = reportAt("2098-12-31T23:59:59Z", command);
        String firstOf2099 = reportAt("2099-01-01T00:00:01Z", command);

        // Then its ticket number is INC-2099-00001
        assertThat(lastOf2098).isEqualTo("INC-2098-00419");
        assertThat(firstOf2099).isEqualTo("INC-2099-00001");
    }

    private String reportAt(String instant, ReportIncidentCommand command) {
        Clock clock = Clock.fixed(Instant.parse(instant), ZoneOffset.UTC);
        return new ReportIncidentService(incidents, ticketNumbers, auditLog, clock).report(command)
                .incident().ticketNumber().value();
    }

    private HttpResponse<String> report(Session session, Map<String, String> body) throws Exception {
        AuthApiClient api = new AuthApiClient(port());
        HttpRequest.Builder request = api.request("/api/v1/tickets")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(JSON.writeValueAsString(body)));
        if (session != null) {
            request.header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken());
        }
        return api.send(request);
    }

    private AuthorizationMatrix matrix() {
        return new AuthorizationMatrix(port());
    }

    private int port() {
        return environment.getRequiredProperty("local.server.port", Integer.class);
    }
}
