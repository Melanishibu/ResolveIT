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
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.TestPropertySource;

/** RIT-US-19 (AB#47) backend Gherkin scenarios: Admin changes incident priority. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class ChangeIncidentPriorityIT {

    private static final String EMPLOYEE_ONE = "00000000-0000-4000-8000-000000000004";

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: Admin changes incident priority
    @Test
    void adminChangesIncidentPriority() throws Exception {
        String id = insertIncident("OPEN", "MEDIUM");

        HttpResponse<String> response = changePriority(Role.ADMIN, id, "CRITICAL");

        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        assertThat(json(response).get("priority").asString()).isEqualTo("CRITICAL");
        assertThat(priorityOf(id)).isEqualTo("CRITICAL");

        var auditEntries = jdbc.sql("SELECT old_value, new_value FROM incident.incident_audit_log WHERE incident_id = :id AND action = 'PRIORITY_CHANGED'")
                .param("id", UUID.fromString(id))
                .query((rs, rowNum) -> rs.getString("old_value") + " -> " + rs.getString("new_value"))
                .list();
        assertThat(auditEntries).containsExactly("MEDIUM -> CRITICAL");
    }

    // Scenario: Setting the same priority again produces no change and no audit entry
    @Test
    void samePriorityProducesNoAuditEntry() throws Exception {
        String id = insertIncident("OPEN", "HIGH");

        HttpResponse<String> response = changePriority(Role.ADMIN, id, "HIGH");

        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        assertThat(json(response).get("priority").asString()).isEqualTo("HIGH");

        int count = jdbc.sql("SELECT COUNT(*) FROM incident.incident_audit_log WHERE incident_id = :id AND action = 'PRIORITY_CHANGED'")
                .param("id", UUID.fromString(id))
                .query(Integer.class)
                .single();
        assertThat(count).isZero();
    }

    // Scenario: Non-admin cannot change priority
    @Test
    void nonAdminCannotChangePriority() throws Exception {
        String id = insertIncident("OPEN", "LOW");

        HttpResponse<String> agentResponse = changePriority(Role.SUPPORT_AGENT, id, "HIGH");
        assertThat(agentResponse.statusCode()).isEqualTo(403);
        assertThat(json(agentResponse).get("code").asString()).isEqualTo("AUTH_FORBIDDEN");

        HttpResponse<String> empResponse = changePriority(Role.EMPLOYEE, id, "HIGH");
        assertThat(empResponse.statusCode()).isEqualTo(403);
        assertThat(json(empResponse).get("code").asString()).isEqualTo("AUTH_FORBIDDEN");

        assertThat(priorityOf(id)).isEqualTo("LOW");
    }

    // Scenario: Priority cannot be changed on a CLOSED incident
    @Test
    void cannotChangePriorityOnClosedIncident() throws Exception {
        String id = insertIncident("CLOSED", "LOW");

        HttpResponse<String> response = changePriority(Role.ADMIN, id, "HIGH");

        assertThat(response.statusCode()).isEqualTo(409);
        assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_CLOSED");
        assertThat(priorityOf(id)).isEqualTo("LOW");
    }

    // Scenario: Unauthenticated caller is rejected
    @Test
    void unauthenticatedCallerIsRejected() throws Exception {
        String id = insertIncident("OPEN", "LOW");

        HttpResponse<String> response = api().send(api().request("/api/v1/tickets/" + id + "/priority")
                .header("Content-Type", "application/json")
                .method("PATCH", HttpRequest.BodyPublishers.ofString("{\"priority\":\"HIGH\"}")));

        assertThat(response.statusCode()).isEqualTo(401);
        assertThat(json(response).get("code").asString()).isEqualTo("AUTH_UNAUTHENTICATED");
    }

    private HttpResponse<String> changePriority(Role role, String id, String priority) throws Exception {
        Session session = matrix().logIn(role);
        return api().send(api().request("/api/v1/tickets/" + id + "/priority")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .method("PATCH", HttpRequest.BodyPublishers.ofString("{\"priority\":\"" + priority + "\"}")));
    }

    private String insertIncident(String status, String priority) throws Exception {
        Session session = matrix().logIn(Role.EMPLOYEE);
        HttpResponse<String> created = api().send(api().request("/api/v1/tickets")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .POST(HttpRequest.BodyPublishers.ofString(
                        "{\"title\":\"Priority test incident\",\"description\":\"Testing priority changes\","
                                + "\"category\":\"HARDWARE\",\"priority\":\"" + priority + "\"}")));
        assertThat(created.statusCode()).isEqualTo(201);
        String id = json(created).get("id").asString();
        if (!"OPEN".equals(status)) {
            jdbc.sql("UPDATE incident.incident SET status = :status WHERE id = :id")
                    .param("status", status)
                    .param("id", UUID.fromString(id))
                    .update();
        }
        return id;
    }

    private String priorityOf(String id) {
        return jdbc.sql("SELECT priority FROM incident.incident WHERE id = :id")
                .param("id", UUID.fromString(id))
                .query(String.class)
                .single();
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
