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
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.TestPropertySource;
import tools.jackson.databind.JsonNode;

/**
 * RIT-US-21 (AB#54) backend Gherkin scenarios. Other tests share this database and audit rows can't be deleted,
 * so the count scenarios compare the counts before and after inserting their own incidents.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class DashboardIT {

    private static final String ADMIN = "00000000-0000-4000-8000-000000000001";
    private static final String AGENT_ONE = "00000000-0000-4000-8000-000000000002";
    private static final String EMPLOYEE_ONE = "00000000-0000-4000-8000-000000000004";
    private static final String EMPLOYEE_TWO = "00000000-0000-4000-8000-000000000005";
    private static final AtomicInteger SEQUENCE = new AtomicInteger();

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: Admin sees counts for all incidents
    @Test
    void adminSeesCountsForAllIncidents() throws Exception {
        JsonNode before = summary(Role.ADMIN);
        insert("OPEN", "CRITICAL", EMPLOYEE_ONE, null);
        insert("OPEN", "LOW", EMPLOYEE_TWO, null);
        insert("OPEN", "LOW", EMPLOYEE_ONE, null);
        insert("ASSIGNED", "CRITICAL", EMPLOYEE_ONE, AGENT_ONE);
        insert("ASSIGNED", "LOW", EMPLOYEE_TWO, AGENT_ONE);
        insert("IN_PROGRESS", "LOW", EMPLOYEE_ONE, AGENT_ONE);
        insert("RESOLVED", "LOW", EMPLOYEE_ONE, AGENT_ONE);
        insert("CLOSED", "CRITICAL", EMPLOYEE_ONE, AGENT_ONE);

        JsonNode after = summary(Role.ADMIN);

        assertThat(delta(before, after, "total")).isEqualTo(8);
        assertThat(delta(before, after, "open")).isEqualTo(3);
        assertThat(delta(before, after, "assigned")).isEqualTo(2);
        assertThat(delta(before, after, "inProgress")).isEqualTo(1);
        assertThat(delta(before, after, "resolved")).isEqualTo(1);
        assertThat(delta(before, after, "critical")).isEqualTo(2);
    }

    // Scenario: Employee sees only their own counts
    @Test
    void employeeSeesOnlyTheirOwnCounts() throws Exception {
        JsonNode before = summary(Role.EMPLOYEE);
        insert("OPEN", "LOW", EMPLOYEE_ONE, null);
        insert("OPEN", "LOW", EMPLOYEE_TWO, null);

        JsonNode after = summary(Role.EMPLOYEE);

        assertThat(delta(before, after, "total")).isEqualTo(1);
        assertThat(delta(before, after, "open")).isEqualTo(1);
    }

    // Scenario: Agent sees only assigned counts
    @Test
    void agentSeesOnlyAssignedCounts() throws Exception {
        JsonNode before = summary(Role.SUPPORT_AGENT);
        insert("ASSIGNED", "LOW", EMPLOYEE_ONE, AGENT_ONE);
        insert("OPEN", "LOW", EMPLOYEE_ONE, null);

        JsonNode after = summary(Role.SUPPORT_AGENT);

        assertThat(delta(before, after, "total")).isEqualTo(1);
        assertThat(delta(before, after, "assigned")).isEqualTo(1);
    }

    // Scenario: Card opens the filtered list (the API side: CRITICAL and not closed)
    @Test
    void cardOpensTheFilteredList() throws Exception {
        String critical = insert("OPEN", "CRITICAL", EMPLOYEE_ONE, null);
        String closed = insert("CLOSED", "CRITICAL", EMPLOYEE_ONE, null);
        String low = insert("OPEN", "LOW", EMPLOYEE_ONE, null);

        JsonNode page = get(Role.ADMIN, "/api/v1/tickets?size=100&priority=CRITICAL"
                + "&status=OPEN&status=ASSIGNED&status=IN_PROGRESS&status=RESOLVED");

        Set<String> numbers = new HashSet<>();
        page.get("items").forEach(item -> {
            numbers.add(item.get("ticketNumber").asString());
            assertThat(item.get("priority").asString()).isEqualTo("CRITICAL");
            assertThat(item.get("status").asString()).isNotEqualTo("CLOSED");
        });
        assertThat(numbers).contains(critical).doesNotContain(closed, low);
    }

    // Scenario: Recent activity respects the role scope
    @Test
    void recentActivityRespectsTheRoleScope() throws Exception {
        String own = insert("OPEN", "LOW", EMPLOYEE_ONE, null);
        String other = insert("OPEN", "LOW", EMPLOYEE_TWO, null);
        audit(own, EMPLOYEE_ONE);
        audit(other, ADMIN);

        JsonNode activity = get(Role.EMPLOYEE, "/api/v1/dashboard/activity?limit=10");

        Set<String> numbers = new HashSet<>();
        activity.forEach(entry -> numbers.add(entry.get("ticketNumber").asString()));
        assertThat(numbers).contains(own).doesNotContain(other);
    }

    /** One incident; returns its ticket number (INC-2080-NNNNN, unique per run). */
    private String insert(String status, String priority, String createdBy, String assignedTo) {
        String number = "INC-2080-" + String.format("%05d", SEQUENCE.incrementAndGet() + (int) (Math.random() * 50_000));
        jdbc.sql("""
                INSERT INTO incident.incident (id, ticket_number, title, description, category, priority, status,
                                               created_by, created_at, updated_at, assigned_to)
                VALUES (gen_random_uuid(), :number, 'Dashboard probe', 'x', 'OTHER', :priority, :status,
                        CAST(:createdBy AS uuid), now(), now(), CAST(:assignedTo AS uuid))
                """)
                .param("number", number).param("priority", priority).param("status", status)
                .param("createdBy", createdBy).param("assignedTo", assignedTo)
                .update();
        return number;
    }

    /** An audit entry dated far in the future, so it is among the latest. */
    private void audit(String ticketNumber, String actor) {
        jdbc.sql("""
                INSERT INTO incident.incident_audit_log (id, incident_id, actor_id, action, old_value, new_value,
                                                         occurred_at)
                SELECT :id, id, CAST(:actor AS uuid), 'CREATED', NULL, ticket_number, TIMESTAMPTZ '2099-01-01'
                FROM incident.incident WHERE ticket_number = :number
                """)
                .param("id", UUID.randomUUID()).param("actor", actor).param("number", ticketNumber)
                .update();
    }

    private static long delta(JsonNode before, JsonNode after, String field) {
        return after.get(field).asLong() - before.get(field).asLong();
    }

    private JsonNode summary(Role role) throws Exception {
        return get(role, "/api/v1/dashboard/summary");
    }

    private JsonNode get(Role role, String path) throws Exception {
        String cookie = new AuthorizationMatrix(port()).logIn(role).cookieHeader();
        HttpResponse<String> response = api().send(api().request(path).GET().header("Cookie", cookie));
        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        return json(response);
    }

    private AuthApiClient api() {
        return new AuthApiClient(port());
    }

    private int port() {
        return environment.getRequiredProperty("local.server.port", Integer.class);
    }
}
