package com.itsm.resolveit.incident.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Role;
import java.net.http.HttpResponse;
import java.util.HashSet;
import java.util.Set;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.TestPropertySource;
import tools.jackson.databind.JsonNode;

/**
 * RIT-US-11 (AB#39) backend Gherkin scenarios. Runs in its own Spring context and database (the extra property),
 * so the incident counts are exact; each test removes the incidents it inserted.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = {
        "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed",
        "resolveit.test.context=incident-list"})
class IncidentListIT {

    private static final String AGENT_ONE = "00000000-0000-4000-8000-000000000002";
    private static final String EMPLOYEE_ONE = "00000000-0000-4000-8000-000000000004";
    private static final String EMPLOYEE_TWO = "00000000-0000-4000-8000-000000000005";

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    @AfterEach
    void removeInsertedIncidents() {
        jdbc.sql("DELETE FROM incident.incident WHERE ticket_number LIKE 'INC-209%'").update();
    }

    // Scenario: Admin sees all incidents
    @Test
    void adminSeesAllIncidents() throws Exception {
        insert(2090, 3, EMPLOYEE_ONE, null, "LOW");
        insert(2091, 2, EMPLOYEE_TWO, null, "LOW");

        JsonNode page = list(Role.ADMIN, "");

        assertThat(page.get("totalItems").asInt()).isEqualTo(5);
        assertThat(page.get("items").get(0).get("ticketNumber").asString()).as("newest first")
                .isEqualTo("INC-2091-00002");
    }

    // Scenario: Employee sees only their own incidents
    @Test
    void employeeSeesOnlyTheirOwnIncidents() throws Exception {
        insert(2090, 3, EMPLOYEE_ONE, null, "LOW");
        insert(2091, 2, EMPLOYEE_TWO, null, "LOW");

        JsonNode page = list(Role.EMPLOYEE, "");

        assertThat(page.get("totalItems").asInt()).isEqualTo(3);
        assertThat(ticketNumbers(page)).allMatch(number -> number.startsWith("INC-2090-"));
    }

    // Scenario: Agent sees only incidents assigned to them
    @Test
    void agentSeesOnlyIncidentsAssignedToThem() throws Exception {
        insert(2090, 2, EMPLOYEE_ONE, AGENT_ONE, "LOW");
        insert(2091, 3, EMPLOYEE_ONE, null, "LOW");

        JsonNode page = list(Role.SUPPORT_AGENT, "");

        assertThat(page.get("totalItems").asInt()).isEqualTo(2);
        assertThat(ticketNumbers(page)).allMatch(number -> number.startsWith("INC-2090-"));
    }

    // Scenario: Paging works
    @Test
    void pagingWorks() throws Exception {
        insert(2090, 45, EMPLOYEE_ONE, null, "LOW");

        JsonNode page = list(Role.ADMIN, "?page=2&size=20");

        assertThat(page.get("items")).hasSize(5);
        assertThat(page.get("totalPages").asInt()).isEqualTo(3);
    }

    // Scenario: Sorting by priority
    @Test
    void sortingByPriority() throws Exception {
        insert(2090, 3, EMPLOYEE_ONE, null, "LOW");
        insert(2091, 1, EMPLOYEE_ONE, null, "CRITICAL");
        insert(2092, 2, EMPLOYEE_ONE, null, "HIGH");

        JsonNode page = list(Role.ADMIN, "?sort=priority,desc");

        assertThat(page.get("items").get(0).get("priority").asString()).isEqualTo("CRITICAL");
        assertThat(page.get("items").get(1).get("priority").asString()).isEqualTo("HIGH");
    }

    // Scenario: Page size is capped
    @Test
    void pageSizeIsCapped() throws Exception {
        HttpResponse<String> response = get(Role.ADMIN, "?size=500");

        assertThat(response.statusCode()).isEqualTo(400);
        assertThat(json(response).get("code").asString()).isEqualTo("VALIDATION_FAILED");
    }

    // Scenario: List stays fast
    @Test
    void listStaysFast() throws Exception {
        insert(2093, 10_000, EMPLOYEE_ONE, null, "MEDIUM");
        get(Role.ADMIN, ""); // warm-up: the first request also loads classes

        long start = System.nanoTime();
        HttpResponse<String> response = get(Role.ADMIN, "");
        long millis = (System.nanoTime() - start) / 1_000_000;

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(millis).as("first page with 10,000 incidents, in ms").isLessThan(1000);
    }

    /** {@code count} incidents INC-{year}-00001.. created one second apart, so later numbers are newer. */
    private void insert(int year, int count, String createdBy, String assignedTo, String priority) {
        jdbc.sql("""
                INSERT INTO incident.incident (id, ticket_number, title, description, category, priority, status,
                                               created_by, created_at, updated_at, assigned_to)
                SELECT gen_random_uuid(), 'INC-' || :year || '-' || lpad(n::text, 5, '0'), 'List probe ' || n, 'x',
                       'OTHER', :priority, 'OPEN', CAST(:createdBy AS uuid),
                       TIMESTAMPTZ '2026-01-01' + make_interval(years => :year - 2090, secs => n),
                       TIMESTAMPTZ '2026-01-01' + make_interval(years => :year - 2090, secs => n),
                       CAST(:assignedTo AS uuid)
                FROM generate_series(1, :count) AS n
                """)
                .param("year", year).param("count", count).param("priority", priority)
                .param("createdBy", createdBy).param("assignedTo", assignedTo)
                .update();
    }

    private static Set<String> ticketNumbers(JsonNode page) {
        Set<String> numbers = new HashSet<>();
        page.get("items").forEach(item -> numbers.add(item.get("ticketNumber").asString()));
        return numbers;
    }

    private JsonNode list(Role role, String query) throws Exception {
        HttpResponse<String> response = get(role, query);
        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        return json(response);
    }

    private HttpResponse<String> get(Role role, String query) throws Exception {
        String cookie = new AuthorizationMatrix(port()).logIn(role).cookieHeader();
        return api().send(api().request("/api/v1/tickets" + query).GET().header("Cookie", cookie));
    }

    private AuthApiClient api() {
        return new AuthApiClient(port());
    }

    private int port() {
        return environment.getRequiredProperty("local.server.port", Integer.class);
    }
}
