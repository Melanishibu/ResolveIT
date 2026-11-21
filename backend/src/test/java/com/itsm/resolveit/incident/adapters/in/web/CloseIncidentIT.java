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
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.TestPropertySource;

/** RIT-US-18 (AB#46) backend Gherkin scenarios, against the dev seed. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class CloseIncidentIT {

    private static final String AGENT_ONE = "00000000-0000-4000-8000-000000000002";

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: TC-011 Employee closes own resolved incident
    @Test
    void tc011EmployeeClosesOwnResolvedIncident() throws Exception {
        String id = incidentIn("RESOLVED");

        HttpResponse<String> response = close(Role.EMPLOYEE, id);

        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        assertThat(json(response).get("status").asString()).isEqualTo("CLOSED");
        assertThat(auditActions(id)).contains("CLOSED");
    }

    // Scenario: Admin closes any resolved incident
    @Test
    void adminClosesAnyResolvedIncident() throws Exception {
        String id = incidentIn("RESOLVED");

        HttpResponse<String> response = close(Role.ADMIN, id);

        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        assertThat(status(id)).isEqualTo("CLOSED");
    }

    // Scenario: Agent cannot close
    @Test
    void agentCannotClose() throws Exception {
        String id = incidentIn("RESOLVED");

        HttpResponse<String> response = close(Role.SUPPORT_AGENT, id);

        assertThat(response.statusCode()).isEqualTo(403);
        assertThat(status(id)).isEqualTo("RESOLVED");
    }

    // Scenario: Only resolved incidents can be closed
    @Test
    void onlyResolvedIncidentsCanBeClosed() throws Exception {
        String id = incidentIn("IN_PROGRESS");

        HttpResponse<String> response = close(Role.EMPLOYEE, id);

        assertThat(response.statusCode()).isEqualTo(409);
        assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_INVALID_TRANSITION");
    }

    /** An incident reported by employee1 and assigned to agent1, moved to {@code status}. */
    private String incidentIn(String status) throws Exception {
        String id = reportIncident();
        jdbc.sql("UPDATE incident.incident SET status = :status, assigned_to = CAST(:agent AS uuid) WHERE id = :id")
                .param("status", status).param("agent", AGENT_ONE).param("id", UUID.fromString(id)).update();
        return id;
    }

    private HttpResponse<String> close(Role role, String incidentId) throws Exception {
        Session session = matrix().logIn(role);
        return api().send(api().request("/api/v1/tickets/" + incidentId + "/status")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .method("PATCH", HttpRequest.BodyPublishers.ofString("{\"targetStatus\":\"CLOSED\"}")));
    }

    private String status(String incidentId) {
        return jdbc.sql("SELECT status FROM incident.incident WHERE id = :id")
                .param("id", UUID.fromString(incidentId)).query(String.class).single();
    }

    private List<String> auditActions(String incidentId) {
        return jdbc.sql("SELECT action FROM incident.incident_audit_log WHERE incident_id = :id")
                .param("id", UUID.fromString(incidentId)).query(String.class).list();
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
