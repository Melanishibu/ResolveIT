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
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.TestPropertySource;
import tools.jackson.databind.JsonNode;

/** RIT-US-14 (AB#42) backend Gherkin scenarios, against the dev seed. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class AssignIncidentIT {

    private static final String ADMIN = "00000000-0000-4000-8000-000000000001";
    private static final String AGENT_ONE = "00000000-0000-4000-8000-000000000002";
    private static final String AGENT_TWO = "00000000-0000-4000-8000-000000000003";
    private static final String EMPLOYEE_ONE = "00000000-0000-4000-8000-000000000004";

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: TC-005 Admin assigns an active agent
    @Test
    void tc005AdminAssignsAnActiveAgent() throws Exception {
        String id = reportIncident();

        HttpResponse<String> response = assign(Role.ADMIN, id, AGENT_ONE);

        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        JsonNode body = json(response);
        assertThat(body.get("status").asString()).isEqualTo("ASSIGNED");
        assertThat(body.get("assignee").get("id").asString()).isEqualTo(AGENT_ONE);
        assertThat(audit(id)).anySatisfy(entry -> {
            assertThat(entry.get("action")).isEqualTo("ASSIGNED");
            assertThat(entry.get("actor_id")).isEqualTo(UUID.fromString(ADMIN));
            assertThat(entry.get("new_value")).isEqualTo(AGENT_ONE);
        });
    }

    // Scenario: TC-006 Employee attempts assignment
    @Test
    void tc006EmployeeAttemptsAssignment() throws Exception {
        String id = reportIncident();

        assertThat(assign(Role.EMPLOYEE, id, AGENT_ONE).statusCode()).isEqualTo(403);
    }

    // Scenario: Inactive agent cannot receive assignments
    @Test
    void inactiveAgentCannotReceiveAssignments() throws Exception {
        HttpResponse<String> response = assign(Role.ADMIN, reportIncident(), AGENT_TWO);

        assertThat(response.statusCode()).isEqualTo(422);
        assertThat(json(response).get("code").asString()).isEqualTo("ASSIGNEE_NOT_ACTIVE_AGENT");
    }

    // Scenario: Only Support Agents can be assignees
    @Test
    void onlySupportAgentsCanBeAssignees() throws Exception {
        HttpResponse<String> response = assign(Role.ADMIN, reportIncident(), EMPLOYEE_ONE);

        assertThat(response.statusCode()).isEqualTo(422);
        assertThat(json(response).get("code").asString()).isEqualTo("ASSIGNEE_NOT_ACTIVE_AGENT");
    }

    // Scenario: Admin reassigns an assigned incident
    @Test
    void adminReassignsAnAssignedIncident() throws Exception {
        String id = reportIncident();
        assertThat(assign(Role.ADMIN, id, AGENT_ONE).statusCode()).isEqualTo(200);
        setActive(AGENT_TWO, true); // the seed's second agent is inactive; restored below
        try {
            HttpResponse<String> response = assign(Role.ADMIN, id, AGENT_TWO);

            assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
            JsonNode body = json(response);
            assertThat(body.get("status").asString()).isEqualTo("ASSIGNED");
            assertThat(body.get("assignee").get("id").asString()).isEqualTo(AGENT_TWO);
            assertThat(audit(id)).anySatisfy(entry -> {
                assertThat(entry.get("action")).isEqualTo("REASSIGNED");
                assertThat(entry.get("old_value")).isEqualTo(AGENT_ONE);
                assertThat(entry.get("new_value")).isEqualTo(AGENT_TWO);
            });
        } finally {
            setActive(AGENT_TWO, false);
        }
    }

    // Scenario: No reassignment once work has started
    @Test
    void noReassignmentOnceWorkHasStarted() throws Exception {
        String id = reportIncident();
        assertThat(assign(Role.ADMIN, id, AGENT_ONE).statusCode()).isEqualTo(200);
        jdbc.sql("UPDATE incident.incident SET status = 'IN_PROGRESS' WHERE id = :id")
                .param("id", UUID.fromString(id)).update();

        HttpResponse<String> response = assign(Role.ADMIN, id, AGENT_ONE);

        assertThat(response.statusCode()).isEqualTo(409);
        assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_INVALID_TRANSITION");
    }

    // Scenario: Agent dropdown lists only active agents
    @Test
    void agentDropdownListsOnlyActiveAgents() throws Exception {
        Session admin = matrix().logIn(Role.ADMIN);
        HttpResponse<String> response = api().send(api().request("/api/v1/users/agents").GET()
                .header("Cookie", admin.cookieHeader()));

        assertThat(response.statusCode()).isEqualTo(200);
        JsonNode agents = json(response);
        assertThat(agents).hasSize(1);
        assertThat(agents.get(0).get("id").asString()).isEqualTo(AGENT_ONE);
    }

    private HttpResponse<String> assign(Role role, String incidentId, String agentId) throws Exception {
        Session session = matrix().logIn(role);
        return api().send(api().request("/api/v1/tickets/" + incidentId + "/assign")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .method("PATCH", HttpRequest.BodyPublishers.ofString("{\"agentId\":\"" + agentId + "\"}")));
    }

    private List<Map<String, Object>> audit(String incidentId) {
        return jdbc.sql("SELECT action, actor_id, old_value, new_value FROM incident.incident_audit_log"
                        + " WHERE incident_id = :id")
                .param("id", UUID.fromString(incidentId)).query().listOfRows();
    }

    private void setActive(String userId, boolean active) {
        jdbc.sql("UPDATE identity.app_user SET active = :active WHERE id = :id")
                .param("active", active).param("id", UUID.fromString(userId)).update();
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
