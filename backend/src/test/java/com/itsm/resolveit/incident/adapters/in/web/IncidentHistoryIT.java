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
import tools.jackson.databind.JsonNode;

/**
 * RIT-US-13 (AB#41) backend Gherkin scenarios for incident history.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class IncidentHistoryIT {

    private static final String AGENT_ONE = "00000000-0000-4000-8000-000000000002";
    private static final String EMPLOYEE_TWO = "00000000-0000-4000-8000-000000000005";

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: TC-014 Authorised user sees the history
    @Test
    void tc014AuthorisedUserSeesTheHistory() throws Exception {
        String id = reportIncident();

        // Assign the incident
        Session adminSession = matrix().logIn(Role.ADMIN);
        HttpResponse<String> assignResponse = api().send(api().request("/api/v1/tickets/" + id + "/assign")
                .header("Content-Type", "application/json")
                .header("Cookie", adminSession.cookieHeader()).header("X-XSRF-TOKEN", adminSession.xsrfToken())
                .method("PATCH", HttpRequest.BodyPublishers.ofString("{\"agentId\":\"" + AGENT_ONE + "\"}")));
        assertThat(assignResponse.statusCode()).isEqualTo(200);

        // When the Admin opens its history
        HttpResponse<String> historyResponse = getHistory(Role.ADMIN, id);
        assertThat(historyResponse.statusCode()).isEqualTo(200);

        // Then they see ASSIGNED and CREATED entries with actor, values and time, newest first
        JsonNode history = json(historyResponse);
        assertThat(history.isArray()).isTrue();
        assertThat(history.size()).isGreaterThanOrEqualTo(2);

        JsonNode newest = history.get(0);
        assertThat(newest.get("action").asString()).isEqualTo("ASSIGNED");
        assertThat(newest.get("actorName").asString()).isNotBlank();
        assertThat(newest.get("newValue").asString()).isNotBlank();
        assertThat(newest.get("occurredAt").asString()).isNotBlank();

        JsonNode previous = history.get(1);
        assertThat(previous.get("action").asString()).isEqualTo("CREATED");
        assertThat(previous.get("actorName").asString()).isNotBlank();
        assertThat(previous.get("occurredAt").asString()).isNotBlank();
    }

    // Scenario: Employee sees history of their own incident
    @Test
    void employeeSeesHistoryOfTheirOwnIncident() throws Exception {
        String id = reportIncident();

        HttpResponse<String> response = getHistory(Role.EMPLOYEE, id);
        assertThat(response.statusCode()).isEqualTo(200);

        JsonNode history = json(response);
        assertThat(history.isArray()).isTrue();
        assertThat(history.size()).isGreaterThanOrEqualTo(1);
        assertThat(history.get(0).get("action").asString()).isEqualTo("CREATED");
    }

    // Scenario: History of someone else's incident is refused
    @Test
    void historyOfSomeoneElsesIncidentIsRefused() throws Exception {
        String id = reportIncident();
        // Move incident to employee2, so employee1 is accessing someone else's incident
        jdbc.sql("UPDATE incident.incident SET created_by = CAST(:owner AS uuid) WHERE id = :id")
                .param("owner", EMPLOYEE_TWO).param("id", UUID.fromString(id)).update();

        HttpResponse<String> response = getHistory(Role.EMPLOYEE, id);
        assertThat(response.statusCode()).isEqualTo(403);
        assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_ACCESS_DENIED");
    }

    // Scenario: History cannot be edited through the API
    @Test
    void historyCannotBeEditedThroughTheApi() throws Exception {
        String id = reportIncident();
        Session adminSession = matrix().logIn(Role.ADMIN);

        // PUT -> 405
        HttpResponse<String> put = api().send(api().request("/api/v1/tickets/" + id + "/history")
                .header("Cookie", adminSession.cookieHeader()).header("X-XSRF-TOKEN", adminSession.xsrfToken())
                .method("PUT", HttpRequest.BodyPublishers.ofString("{}")));
        assertThat(put.statusCode()).isEqualTo(405);

        // PATCH -> 405
        HttpResponse<String> patch = api().send(api().request("/api/v1/tickets/" + id + "/history")
                .header("Cookie", adminSession.cookieHeader()).header("X-XSRF-TOKEN", adminSession.xsrfToken())
                .method("PATCH", HttpRequest.BodyPublishers.ofString("{}")));
        assertThat(patch.statusCode()).isEqualTo(405);

        // DELETE -> 405
        HttpResponse<String> delete = api().send(api().request("/api/v1/tickets/" + id + "/history")
                .header("Cookie", adminSession.cookieHeader()).header("X-XSRF-TOKEN", adminSession.xsrfToken())
                .method("DELETE", HttpRequest.BodyPublishers.noBody()));
        assertThat(delete.statusCode()).isEqualTo(405);
    }

    private HttpResponse<String> getHistory(Role role, String incidentId) throws Exception {
        Session session = matrix().logIn(role);
        return api().send(api().request("/api/v1/tickets/" + incidentId + "/history").GET()
                .header("Cookie", session.cookieHeader()));
    }

    private String reportIncident() throws Exception {
        Session session = matrix().logIn(Role.EMPLOYEE);
        HttpResponse<String> created = api().send(api().request("/api/v1/tickets")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .POST(HttpRequest.BodyPublishers.ofString(
                        "{\"title\":\"History test printer\",\"description\":\"Paper jam\","
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
