package com.itsm.resolveit.incident.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Role;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Session;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.TestPropertySource;

/** RIT-US-17 (AB#45) backend Gherkin scenarios, against the dev seed. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class ReopenIncidentIT {

    private static final String AGENT_ONE = "00000000-0000-4000-8000-000000000002";
    private static final String EMPLOYEE_TWO = "00000000-0000-4000-8000-000000000005";
    private static final String REASON = "The laptop still does not start";

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: Employee reopens their resolved incident
    @Test
    void employeeReopensTheirResolvedIncident() throws Exception {
        String id = incidentIn("RESOLVED");

        HttpResponse<String> response = reopen(Role.EMPLOYEE, id, REASON);

        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        assertThat(json(response).get("status").asString()).isEqualTo("IN_PROGRESS");
        assertThat(jdbc.sql("SELECT new_value FROM incident.incident_audit_log WHERE incident_id = :id"
                        + " AND action = 'REOPENED'")
                .param("id", UUID.fromString(id)).query(String.class).list()).containsExactly(REASON);
    }

    // Scenario: Assigned agent reopens
    @Test
    void assignedAgentReopens() throws Exception {
        String id = incidentIn("RESOLVED");

        HttpResponse<String> response = reopen(Role.SUPPORT_AGENT, id, REASON);

        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        assertThat(status(id)).isEqualTo("IN_PROGRESS");
    }

    // Scenario: Reason is required
    @Test
    void reasonIsRequired() throws Exception {
        String id = incidentIn("RESOLVED");

        HttpResponse<String> response = reopen(Role.EMPLOYEE, id, "");

        assertThat(response.statusCode()).isEqualTo(400);
        assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_REOPEN_REASON_REQUIRED");
        assertThat(status(id)).isEqualTo("RESOLVED");
    }

    // Scenario: Other employees cannot reopen
    // employee2 is locked by AuthLoginIT, so the incident's creator is moved to employee2 and employee1 tries
    // (same rule, same answer).
    @Test
    void otherEmployeesCannotReopen() throws Exception {
        String id = incidentIn("RESOLVED");
        jdbc.sql("UPDATE incident.incident SET created_by = CAST(:owner AS uuid) WHERE id = :id")
                .param("owner", EMPLOYEE_TWO).param("id", UUID.fromString(id)).update();

        HttpResponse<String> response = reopen(Role.EMPLOYEE, id, REASON);

        assertThat(response.statusCode()).isEqualTo(403);
        assertThat(status(id)).isEqualTo("RESOLVED");
    }

    private HttpResponse<String> reopen(Role role, String incidentId, String reason) throws Exception {
        Session session = matrix().logIn(role);
        return api().send(api().request("/api/v1/tickets/" + incidentId + "/status")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .method("PATCH", HttpRequest.BodyPublishers.ofString(
                        "{\"targetStatus\":\"IN_PROGRESS\",\"reason\":\"" + reason + "\"}")));
    }

    /** An incident reported by employee1 and assigned to agent1, moved to {@code status}. */
    private String incidentIn(String status) throws Exception {
        String id = reportIncident();
        jdbc.sql("UPDATE incident.incident SET status = :status, assigned_to = CAST(:agent AS uuid) WHERE id = :id")
                .param("status", status).param("agent", AGENT_ONE).param("id", UUID.fromString(id)).update();
        return id;
    }

    private String status(String incidentId) {
        return jdbc.sql("SELECT status FROM incident.incident WHERE id = :id")
                .param("id", UUID.fromString(incidentId)).query(String.class).single();
    }

    private String reportIncident() throws Exception {
        Session session = matrix().logIn(Role.EMPLOYEE);
        HttpResponse<String> created = api().send(api().request("/api/v1/tickets")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .POST(HttpRequest.BodyPublishers.ofString(
                        "{\"title\":\"Printer jams\",\"description\":\"Paper jam on floor 2\","
                                + "\"category\":\"HARDWARE\",\"priority\":\"LOW\"}")));
        assertThat(created.statusCode()).isEqualTo(201);
        return json(created).get("id").asString();
    }

    private AuthorizationMatrix matrix() {
        return new AuthorizationMatrix(port());
    }

    private AuthApiClient api() {
        return new AuthApiClient(port());
    }

    private int port() {
        return environment.getRequiredProperty("local.server.port", Integer.class);
    }
}
