package com.itsm.resolveit.identity.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Role;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Session;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/** RIT-US-22 (AB#52) backend Gherkin scenarios: Admin resends invitation. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class ResendInvitationIT {

    @SuppressWarnings("resource")
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

    // Scenario: Admin resends an invitation
    @Test
    void adminResendsInvitation() throws Exception {
        Session admin = matrix().logIn(Role.ADMIN);
        String email = "resend." + System.nanoTime() + "@resolveit.local";

        HttpResponse<String> created = create(admin, Map.of("name", "Resend Test", "email", email,
                "role", "EMPLOYEE", "department", "Engineering"));
        assertThat(created.statusCode()).isEqualTo(201);
        String userId = json(created).get("id").asString();

        // Resend invitation
        HttpResponse<String> response = resend(admin, userId);
        assertThat(response.statusCode()).as(response.body()).isEqualTo(200);
        JsonNode row = json(response);
        assertThat(row.get("id").asString()).isEqualTo(userId);
        assertThat(row.get("invitationStatus").asString()).isIn("PENDING", "SENT");

        // Verify audit log has INVITATION_RESENT
        var auditActions = jdbc.sql("""
                SELECT action FROM identity.user_audit_log
                WHERE user_id = :id::uuid
                ORDER BY occurred_at""").param("id", userId).query(String.class).list();
        assertThat(auditActions).contains("INVITATION_RESENT");

        // Verify there are 2 invitations and the earlier one is expired
        var invitations = jdbc.sql("""
                SELECT expires_at, status FROM identity.invitation
                WHERE user_id = :id::uuid
                ORDER BY created_at ASC""").param("id", userId)
                .query((rs, rowNum) -> rs.getTimestamp("expires_at").toInstant())
                .list();
        assertThat(invitations).hasSize(2);
        assertThat(invitations.get(0)).isBeforeOrEqualTo(Instant.now());
    }

    // Scenario: User who already set a password cannot be re-invited
    @Test
    void userWithPasswordCannotBeReinvited() throws Exception {
        Session admin = matrix().logIn(Role.ADMIN);
        // employee1 from seed has a password
        String employee1Id = "00000000-0000-4000-8000-000000000004";

        HttpResponse<String> response = resend(admin, employee1Id);

        assertThat(response.statusCode()).isEqualTo(409);
        assertThat(json(response).get("code").asString()).isEqualTo("USER_ALREADY_ACTIVATED");
    }

    // Scenario: Unknown user gives 404 USER_NOT_FOUND
    @Test
    void unknownUserReturns404() throws Exception {
        Session admin = matrix().logIn(Role.ADMIN);

        HttpResponse<String> response = resend(admin, UUID.randomUUID().toString());

        assertThat(response.statusCode()).isEqualTo(404);
        assertThat(json(response).get("code").asString()).isEqualTo("USER_NOT_FOUND");
    }

    // Scenario: Non-admin cannot resend invitation
    @Test
    void nonAdminCannotResendInvitation() throws Exception {
        Session agent = matrix().logIn(Role.SUPPORT_AGENT);
        Session employee = matrix().logIn(Role.EMPLOYEE);
        String userId = "00000000-0000-4000-8000-000000000005";

        HttpResponse<String> agentResponse = resend(agent, userId);
        assertThat(agentResponse.statusCode()).isEqualTo(403);
        assertThat(json(agentResponse).get("code").asString()).isEqualTo("AUTH_FORBIDDEN");

        HttpResponse<String> empResponse = resend(employee, userId);
        assertThat(empResponse.statusCode()).isEqualTo(403);
        assertThat(json(empResponse).get("code").asString()).isEqualTo("AUTH_FORBIDDEN");
    }

    // Scenario: Unauthenticated caller is rejected
    @Test
    void unauthenticatedCallerIsRejected() throws Exception {
        HttpResponse<String> response = api().send(api().request("/api/v1/users/" + UUID.randomUUID() + "/invitation")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.noBody()));

        assertThat(response.statusCode()).isEqualTo(401);
        assertThat(json(response).get("code").asString()).isEqualTo("AUTH_UNAUTHENTICATED");
    }

    private HttpResponse<String> resend(Session session, String userId) throws Exception {
        return api().send(api().request("/api/v1/users/" + userId + "/invitation")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .POST(HttpRequest.BodyPublishers.noBody()));
    }

    private HttpResponse<String> create(Session session, Map<String, Object> body) throws Exception {
        return api().send(api().request("/api/v1/users")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .POST(HttpRequest.BodyPublishers.ofString(JSON.writeValueAsString(body))));
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
