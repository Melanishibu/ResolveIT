package com.itsm.resolveit.identity.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Role;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Session;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/** RIT-US-06 (AB#48) backend Gherkin scenarios, with a real Mailpit as the mail server. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class CreateUserIT {

    @SuppressWarnings("resource") // stopped by Testcontainers' Ryuk when the JVM ends
    static final GenericContainer<?> MAILPIT = new GenericContainer<>(DockerImageName.parse("axllent/mailpit:v1.34"))
            .withExposedPorts(1025, 8025)
            .waitingFor(Wait.forHttp("/readyz").forPort(8025));

    static {
        MAILPIT.start();
    }

    @DynamicPropertySource
    static void mailServer(DynamicPropertyRegistry registry) {
        registry.add("spring.mail.host", MAILPIT::getHost);
        registry.add("spring.mail.port", () -> MAILPIT.getMappedPort(1025));
    }

    private static final JsonMapper JSON = JsonMapper.builder().build();

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: Admin creates a Support Agent
    @Test
    void adminCreatesASupportAgent() throws Exception {
        Session admin = matrix().logIn(Role.ADMIN);

        HttpResponse<String> response = create(admin,
                Map.of("name", "Asha Rao", "email", "asha@resolveit.local", "role", "SUPPORT_AGENT",
                        "department", "IT Support"));

        assertThat(response.statusCode()).isEqualTo(201);
        JsonNode created = json(response);
        assertThat(created.get("active").asBoolean()).isTrue();
        assertThat(created.get("role").asString()).isEqualTo("SUPPORT_AGENT");
        assertThat(created.get("department").asString()).isEqualTo("IT Support");
        String userId = created.get("id").asString();
        assertThat(jdbc.sql("SELECT password_hash FROM identity.app_user WHERE id = :id::uuid").param("id", userId)
                .query(String.class).optional()).as("no password").isEmpty();

        JsonNode message = latestMailTo("asha@resolveit.local");
        assertThat(message.get("Subject").asString()).isEqualTo("Your ResolveIT account");
        String body = mailText(message.get("ID").asString());
        assertThat(body).contains("Asha Rao").contains("Technician").contains("http://localhost:5000/set-password?token=");

        assertThat(jdbc.sql("""
                SELECT action FROM identity.user_audit_log
                WHERE user_id = :id::uuid AND actor_id = '00000000-0000-4000-8000-000000000001'::uuid
                ORDER BY occurred_at""").param("id", userId).query(String.class).list())
                .containsExactlyInAnyOrder("USER_CREATED", "INVITATION_SENT");
        assertThat(jdbc.sql("SELECT status FROM identity.invitation WHERE user_id = :id::uuid").param("id", userId)
                .query(String.class).single()).isEqualTo("SENT");
    }

    // Scenario: Email never contains a password (the real email, as received by Mailpit)
    @Test
    void emailNeverContainsAPassword() throws Exception {
        create(matrix().logIn(Role.ADMIN), Map.of("name", "Ravi Kumar", "email", "ravi@resolveit.local",
                "role", "EMPLOYEE", "department", "Finance"));

        String body = mailText(latestMailTo("ravi@resolveit.local").get("ID").asString());

        assertThat(body).contains("/set-password?token=").doesNotContain("ResolveIT-Dev-2026")
                .doesNotContainIgnoringCase("password:");
    }

    // Scenario: Duplicate email is rejected
    @Test
    void duplicateEmailIsRejected() throws Exception {
        HttpResponse<String> response = create(matrix().logIn(Role.ADMIN), Map.of("name", "Someone",
                "email", "EMPLOYEE1@resolveit.local", "role", "EMPLOYEE", "department", "Finance"));

        assertThat(response.statusCode()).isEqualTo(409);
        assertThat(json(response).get("code").asString()).isEqualTo("USER_EMAIL_TAKEN");
    }

    // Scenario: Admin cannot create another Admin
    @Test
    void adminCannotCreateAnotherAdmin() throws Exception {
        HttpResponse<String> response = create(matrix().logIn(Role.ADMIN), Map.of("name", "Second Admin",
                "email", "admin2@resolveit.local", "role", "ADMIN", "department", "IT"));

        assertThat(response.statusCode()).isEqualTo(400);
        assertThat(json(response).get("code").asString()).isEqualTo("USER_ROLE_NOT_ALLOWED");
    }

    // Scenario: Non-admin cannot create users
    @Test
    void nonAdminCannotCreateUsers() throws Exception {
        HttpResponse<String> agent = create(matrix().logIn(Role.SUPPORT_AGENT), Map.of("name", "X",
                "email", "x@resolveit.local", "role", "EMPLOYEE", "department", "Finance"));

        assertThat(agent.statusCode()).isEqualTo(403);
        assertThat(json(agent).get("code").asString()).isEqualTo("AUTH_FORBIDDEN");
        assertThat(create(matrix().logIn(Role.EMPLOYEE), Map.of("name", "Y", "email", "y@resolveit.local",
                "role", "EMPLOYEE", "department", "Finance")).statusCode()).isEqualTo(403);
        assertThat(create(null, Map.of()).statusCode()).as("anonymous").isEqualTo(401);
    }

    // Scenario: Department is required
    @Test
    void departmentIsRequired() throws Exception {
        HttpResponse<String> response = create(matrix().logIn(Role.ADMIN), Map.of("name", "No Department",
                "email", "nodept@resolveit.local", "role", "EMPLOYEE"));

        assertThat(response.statusCode()).isEqualTo(400);
        JsonNode problem = json(response);
        assertThat(problem.get("code").asString()).isEqualTo("VALIDATION_FAILED");
        assertThat(problem.get("params").get("fields").toString()).contains("department");
    }

    @Test
    void theDatabaseRefusesToChangeOrDeleteUserAuditEntries() {
        jdbc.sql("""
                INSERT INTO identity.user_audit_log (id, user_id, action, occurred_at)
                VALUES (gen_random_uuid(), '00000000-0000-4000-8000-000000000004'::uuid, 'USER_CREATED', now())
                """).update();

        assertThatThrownBy(() -> jdbc.sql("UPDATE identity.user_audit_log SET action = 'X'").update())
                .isInstanceOf(DataAccessException.class);
        assertThatThrownBy(() -> jdbc.sql("DELETE FROM identity.user_audit_log").update())
                .isInstanceOf(DataAccessException.class);
        assertThatThrownBy(() -> jdbc.sql("TRUNCATE identity.user_audit_log").update())
                .isInstanceOf(DataAccessException.class);
    }

    private HttpResponse<String> create(Session session, Map<String, String> body) throws Exception {
        AuthApiClient api = new AuthApiClient(port());
        HttpRequest.Builder request = api.request("/api/v1/users")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(JSON.writeValueAsString(body)));
        if (session != null) {
            request.header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken());
        }
        return api.send(request);
    }

    private static JsonNode latestMailTo(String address) throws Exception {
        JsonNode messages = mailpit("/api/v1/messages").get("messages");
        for (JsonNode message : messages) {
            for (JsonNode to : message.get("To")) {
                if (address.equals(to.get("Address").asString())) {
                    return message;
                }
            }
        }
        throw new AssertionError("No email to " + address + " in Mailpit; messages: " + List.of(messages.toString()));
    }

    private static String mailText(String id) throws Exception {
        return mailpit("/api/v1/message/" + id).get("Text").asString();
    }

    private static JsonNode mailpit(String path) throws Exception {
        URI uri = URI.create("http://" + MAILPIT.getHost() + ":" + MAILPIT.getMappedPort(8025) + path);
        HttpResponse<String> response = HttpClient.newHttpClient()
                .send(HttpRequest.newBuilder(uri).GET().build(), HttpResponse.BodyHandlers.ofString());
        return JSON.readTree(response.body());
    }

    private AuthorizationMatrix matrix() {
        return new AuthorizationMatrix(port());
    }

    private int port() {
        return environment.getRequiredProperty("local.server.port", Integer.class);
    }
}
