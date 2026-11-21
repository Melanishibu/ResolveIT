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

/** RIT-US-15 (AB#43) backend Gherkin scenarios, against the dev seed. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class IncidentStatusIT {

    private static final String AGENT_ONE = "00000000-0000-4000-8000-000000000002";
    private static final String AGENT_TWO = "00000000-0000-4000-8000-000000000003";

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: TC-007 Agent starts work on an assigned incident
    @Test
    void tc007AgentStartsWorkOnAnAssignedIncident() throws Exception {
        String id = reportIncident();
        setState(id, "ASSIGNED", AGENT_ONE);

        HttpResponse<String> response = changeStatus(Role.SUPPORT_AGENT, id, "IN_PROGRESS");

        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        assertThat(json(response).get("status").asString()).isEqualTo("IN_PROGRESS");
        assertThat(auditActions(id)).contains("STARTED");
    }

    // Scenario: TC-008 Agent cannot change another agent's incident
    @Test
    void tc008AgentCannotChangeAnotherAgentsIncident() throws Exception {
        String id = reportIncident();
        setState(id, "ASSIGNED", AGENT_TWO);

        HttpResponse<String> response = changeStatus(Role.SUPPORT_AGENT, id, "IN_PROGRESS");

        assertThat(response.statusCode()).isEqualTo(403);
        assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_ACCESS_DENIED");
    }

    // Scenario: TC-012 Invalid transition is rejected
    @Test
    void tc012InvalidTransitionIsRejected() throws Exception {
        String id = reportIncident();

        HttpResponse<String> response = changeStatus(Role.ADMIN, id, "CLOSED");

        assertThat(response.statusCode()).isEqualTo(409);
        assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_INVALID_TRANSITION");
        assertThat(status(id)).isEqualTo("OPEN");
    }

    // Scenario: Closed incidents are final
    @Test
    void closedIncidentsAreFinal() throws Exception {
        String id = reportIncident();
        setState(id, "CLOSED", AGENT_ONE);

        for (String target : List.of("OPEN", "ASSIGNED", "IN_PROGRESS", "RESOLVED", "CLOSED")) {
            HttpResponse<String> response = changeStatus(Role.ADMIN, id, target);

            assertThat(response.statusCode()).as(target).isEqualTo(409);
            assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_INVALID_TRANSITION");
        }
        assertThat(status(id)).isEqualTo("CLOSED");
    }

    private HttpResponse<String> changeStatus(Role role, String incidentId, String target) throws Exception {
        Session session = matrix().logIn(role);
        return api().send(api().request("/api/v1/tickets/" + incidentId + "/status")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .method("PATCH", HttpRequest.BodyPublishers.ofString("{\"targetStatus\":\"" + target + "\"}")));
    }

    private void setState(String incidentId, String status, String assignee) {
        jdbc.sql("UPDATE incident.incident SET status = :status, assigned_to = CAST(:assignee AS uuid) WHERE id = :id")
                .param("status", status).param("assignee", assignee).param("id", UUID.fromString(incidentId))
                .update();
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
