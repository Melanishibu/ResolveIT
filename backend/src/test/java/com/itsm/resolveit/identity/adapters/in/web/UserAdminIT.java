package com.itsm.resolveit.identity.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Role;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Session;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.TestPropertySource;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * RIT-US-08 (AB#50) backend Gherkin scenarios. The seed users are shared with other test classes, so
 * every status change is undone at the end of its test.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class UserAdminIT {

    private static final String ADMIN_ID = "00000000-0000-4000-8000-000000000001";
    private static final String AGENT1_ID = "00000000-0000-4000-8000-000000000002";
    private static final String AGENT2_ID = "00000000-0000-4000-8000-000000000003";
    private static final JsonMapper JSON = JsonMapper.builder().build();

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: Admin sees all users with their status
    @Test
    void adminSeesAllUsersWithTheirStatus() throws Exception {
        Session admin = matrix().logIn(Role.ADMIN);
        long totalUsers = jdbc.sql("SELECT count(*) FROM identity.app_user").query(Long.class).single();

        HttpResponse<String> response = get(admin, "/api/v1/users");

        assertThat(response.statusCode()).isEqualTo(200);
        JsonNode page = json(response);
        assertThat(page.get("page").asInt()).isZero();
        assertThat(page.get("size").asInt()).as("20 per page").isEqualTo(20);
        assertThat(page.get("totalItems").asLong()).as("every user").isEqualTo(totalUsers);
        JsonNode agent2 = row(page, "agent2@resolveit.local");
        assertThat(agent2.get("role").asString()).isEqualTo("SUPPORT_AGENT");
        assertThat(agent2.get("active").asBoolean()).isFalse();
        assertThat(agent2.get("invitationStatus").asString()).as("seed user with a password").isEqualTo("ACCEPTED");
        assertThat(agent2.get("department").asString()).isNotBlank();

        JsonNode agents = json(get(admin, "/api/v1/users?role=SUPPORT_AGENT&active=true&q=AGENT&sort=email,desc&size=1"));
        assertThat(agents.get("items")).hasSize(1);
        assertThat(agents.get("items").get(0).get("email").asString()).isEqualTo("agent1@resolveit.local");
        assertThat(agents.get("totalPages").asInt()).isEqualTo(agents.get("totalItems").asInt());
        assertThat(get(admin, "/api/v1/users?size=101").statusCode()).as("max 100").isEqualTo(400);
        assertThat(json(get(admin, "/api/v1/users?sort=password,asc")).get("code").asString())
                .isEqualTo("VALIDATION_FAILED");
    }

    // Scenario: Admin deactivates an Agent
    @Test
    void adminDeactivatesAnAgent() throws Exception {
        Session admin = matrix().logIn(Role.ADMIN);
        try {
            HttpResponse<String> response = patchStatus(admin, AGENT1_ID, false);

            assertThat(response.statusCode()).isEqualTo(200);
            assertThat(json(response).get("active").asBoolean()).isFalse();
            assertThat(api().logIn("agent1@resolveit.local", AuthApiClient.PASSWORD).statusCode())
                    .as("cannot log in").isEqualTo(401);
            assertThat(auditActions(AGENT1_ID)).contains("USER_DEACTIVATED");
        } finally {
            jdbc.sql("UPDATE identity.app_user SET active = true WHERE id = :id::uuid").param("id", AGENT1_ID).update();
        }
    }

    // Scenario: Admin reactivates a user
    @Test
    void adminReactivatesAUser() throws Exception {
        Session admin = matrix().logIn(Role.ADMIN);
        assertThat(api().logIn("agent2@resolveit.local", AuthApiClient.PASSWORD).statusCode())
                .as("the seed Agent 2 is inactive").isEqualTo(401);
        try {
            HttpResponse<String> response = patchStatus(admin, AGENT2_ID, true);

            assertThat(response.statusCode()).isEqualTo(200);
            assertThat(api().logIn("agent2@resolveit.local", AuthApiClient.PASSWORD).statusCode())
                    .as("can log in again").isEqualTo(200);
            assertThat(auditActions(AGENT2_ID)).contains("USER_ACTIVATED");
        } finally {
            jdbc.sql("UPDATE identity.app_user SET active = false WHERE id = :id::uuid").param("id", AGENT2_ID).update();
        }
    }

    // Scenario: Admin cannot deactivate themselves
    @Test
    void adminCannotDeactivateThemselves() throws Exception {
        HttpResponse<String> response = patchStatus(matrix().logIn(Role.ADMIN), ADMIN_ID, false);

        assertThat(response.statusCode()).isEqualTo(409);
        assertThat(json(response).get("code").asString()).isEqualTo("USER_CANNOT_DEACTIVATE_SELF");
        assertThat(jdbc.sql("SELECT active FROM identity.app_user WHERE id = :id::uuid").param("id", ADMIN_ID)
                .query(Boolean.class).single()).isTrue();
        HttpResponse<String> unknown = patchStatus(matrix().logIn(Role.ADMIN),
                "00000000-0000-4000-8000-0000000000ff", false);
        assertThat(unknown.statusCode()).isEqualTo(404);
        assertThat(json(unknown).get("code").asString()).isEqualTo("USER_NOT_FOUND");
    }

    // Scenario: Only Admins see the user list
    @Test
    void onlyAdminsSeeTheUserList() throws Exception {
        HttpResponse<String> employee = get(matrix().logIn(Role.EMPLOYEE), "/api/v1/users");

        assertThat(employee.statusCode()).isEqualTo(403);
        assertThat(json(employee).get("code").asString()).isEqualTo("AUTH_FORBIDDEN");
        assertThat(get(matrix().logIn(Role.SUPPORT_AGENT), "/api/v1/users").statusCode()).isEqualTo(403);
        assertThat(get(null, "/api/v1/users").statusCode()).as("anonymous").isEqualTo(401);
        assertThat(patchStatus(matrix().logIn(Role.EMPLOYEE), AGENT1_ID, false).statusCode()).isEqualTo(403);
    }

    private List<String> auditActions(String userId) {
        return new ArrayList<>(jdbc.sql("""
                SELECT action FROM identity.user_audit_log
                WHERE user_id = :id::uuid AND actor_id = :admin::uuid""")
                .param("id", userId).param("admin", ADMIN_ID).query(String.class).list());
    }

    private static JsonNode row(JsonNode page, String email) {
        for (JsonNode item : page.get("items")) {
            if (email.equals(item.get("email").asString())) {
                return item;
            }
        }
        throw new AssertionError("no row for " + email + " in " + page);
    }

    private HttpResponse<String> get(Session session, String path) throws Exception {
        HttpRequest.Builder request = api().request(path).GET();
        if (session != null) {
            request.header("Cookie", session.cookieHeader());
        }
        return api().send(request);
    }

    private HttpResponse<String> patchStatus(Session session, String userId, boolean active) throws Exception {
        return api().send(api().request("/api/v1/users/" + userId + "/status")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .method("PATCH", HttpRequest.BodyPublishers.ofString(JSON.writeValueAsString(Map.of("active", active)))));
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
