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
 * RIT-US-20 (AB#53) backend Gherkin scenarios, against the dev seed. employee2 is locked by AuthLoginIT, so the
 * "employee2 requests employee1's comments" scenario is played the other way round: the incident's creator is
 * moved to employee2 and employee1 requests it (same rule, same answer).
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class IncidentCommentsIT {

    private static final String AGENT_ONE = "00000000-0000-4000-8000-000000000002";
    private static final String EMPLOYEE_ONE = "00000000-0000-4000-8000-000000000004";
    private static final String EMPLOYEE_TWO = "00000000-0000-4000-8000-000000000005";

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: TC-013 Add authorised comment
    @Test
    void tc013AddAuthorisedComment() throws Exception {
        String id = reportIncident();

        HttpResponse<String> created = addComment(Role.EMPLOYEE, id, "It happens every morning");

        assertThat(created.statusCode()).as(created.body()).isEqualTo(201);
        JsonNode comment = json(created);
        assertThat(comment.get("author").get("id").asString()).isEqualTo(EMPLOYEE_ONE);
        assertThat(comment.get("author").get("name").asString()).isNotBlank();
        assertThat(comment.get("createdAt").asString()).isNotBlank();
        JsonNode page = json(listComments(Role.EMPLOYEE, id));
        assertThat(page.get("totalItems").asInt()).isEqualTo(1);
        assertThat(page.get("items").get(0).get("text").asString()).isEqualTo("It happens every morning");
    }

    // Scenario: Agent comments on an assigned incident
    @Test
    void agentCommentsOnAnAssignedIncident() throws Exception {
        String id = reportIncident();
        jdbc.sql("UPDATE incident.incident SET status = 'ASSIGNED', assigned_to = CAST(:agent AS uuid) WHERE id = :id")
                .param("agent", AGENT_ONE).param("id", UUID.fromString(id)).update();

        HttpResponse<String> created = addComment(Role.SUPPORT_AGENT, id, "Looking into it");

        assertThat(created.statusCode()).as(created.body()).isEqualTo(201);
    }

    // Scenario: Unauthorised user cannot read or add comments
    @Test
    void unauthorisedUserCannotReadOrAddComments() throws Exception {
        String id = reportIncident();
        jdbc.sql("UPDATE incident.incident SET created_by = CAST(:owner AS uuid) WHERE id = :id")
                .param("owner", EMPLOYEE_TWO).param("id", UUID.fromString(id)).update();

        HttpResponse<String> read = listComments(Role.EMPLOYEE, id);
        HttpResponse<String> add = addComment(Role.EMPLOYEE, id, "Me too");

        assertThat(read.statusCode()).isEqualTo(403);
        assertThat(json(read).get("code").asString()).isEqualTo("INCIDENT_ACCESS_DENIED");
        assertThat(add.statusCode()).isEqualTo(403);
        assertThat(json(add).get("code").asString()).isEqualTo("INCIDENT_ACCESS_DENIED");
    }

    // Scenario: Closed incident accepts no comments
    @Test
    void closedIncidentAcceptsNoComments() throws Exception {
        String id = reportIncident();
        jdbc.sql("UPDATE incident.incident SET status = 'CLOSED' WHERE id = :id")
                .param("id", UUID.fromString(id)).update();

        HttpResponse<String> response = addComment(Role.EMPLOYEE, id, "Still broken");

        assertThat(response.statusCode()).isEqualTo(409);
        assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_CLOSED");
    }

    // Scenario: Empty comment is rejected
    @Test
    void emptyCommentIsRejected() throws Exception {
        String id = reportIncident();

        HttpResponse<String> response = addComment(Role.EMPLOYEE, id, "   ");

        assertThat(response.statusCode()).isEqualTo(400);
        assertThat(json(response).get("code").asString()).isEqualTo("VALIDATION_FAILED");
    }

    private HttpResponse<String> addComment(Role role, String incidentId, String text) throws Exception {
        Session session = matrix().logIn(role);
        return api().send(api().request("/api/v1/tickets/" + incidentId + "/comments")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .POST(HttpRequest.BodyPublishers.ofString("{\"text\":\"" + text + "\"}")));
    }

    private HttpResponse<String> listComments(Role role, String incidentId) throws Exception {
        Session session = matrix().logIn(role);
        return api().send(api().request("/api/v1/tickets/" + incidentId + "/comments").GET()
                .header("Cookie", session.cookieHeader()));
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
