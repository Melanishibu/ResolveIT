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
import tools.jackson.databind.JsonNode;

/** RIT-US-16 (AB#44) backend Gherkin scenarios, against the dev seed. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class ResolveIncidentIT {

    private static final String AGENT_ONE = "00000000-0000-4000-8000-000000000002";

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: TC-010 Resolve with valid notes
    @Test
    void tc010ResolveWithValidNotes() throws Exception {
        String id = inProgressIncident();

        HttpResponse<String> response = resolve(Role.SUPPORT_AGENT, id, "Replaced the faulty power adapter");

        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        JsonNode body = json(response);
        assertThat(body.get("status").asString()).isEqualTo("RESOLVED");
        assertThat(body.get("resolutionNotes").asString()).isEqualTo("Replaced the faulty power adapter");
        assertThat(auditActions(id)).contains("RESOLVED");
    }

    // Scenario: TC-009 Resolve without resolution notes
    @Test
    void tc009ResolveWithoutResolutionNotes() throws Exception {
        String id = inProgressIncident();

        HttpResponse<String> response = resolve(Role.SUPPORT_AGENT, id, "");

        assertThat(response.statusCode()).isEqualTo(400);
        assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_RESOLUTION_NOTES_REQUIRED");
        assertThat(status(id)).isEqualTo("IN_PROGRESS");
    }

    // Scenario: Employee cannot resolve
    @Test
    void employeeCannotResolve() throws Exception {
        String id = inProgressIncident();

        HttpResponse<String> response = resolve(Role.EMPLOYEE, id, "Replaced the faulty power adapter");

        assertThat(response.statusCode()).isEqualTo(403);
        assertThat(status(id)).isEqualTo("IN_PROGRESS");
    }

    private String inProgressIncident() throws Exception {
        String id = reportIncident();
        jdbc.sql("UPDATE incident.incident SET status = 'IN_PROGRESS', assigned_to = CAST(:agent AS uuid)"
                        + " WHERE id = :id")
                .param("agent", AGENT_ONE).param("id", UUID.fromString(id)).update();
        return id;
    }

    private HttpResponse<String> resolve(Role role, String incidentId, String notes) throws Exception {
        Session session = matrix().logIn(role);
        return api().send(api().request("/api/v1/tickets/" + incidentId + "/status")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .method("PATCH", HttpRequest.BodyPublishers.ofString(
                        "{\"targetStatus\":\"RESOLVED\",\"resolutionNotes\":\"" + notes + "\"}")));
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
                        "{\"title\":\"Laptop won't start\",\"description\":\"Black screen\","
                                + "\"category\":\"HARDWARE\",\"priority\":\"HIGH\"}")));
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
