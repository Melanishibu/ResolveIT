package com.itsm.resolveit.identity.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/** RIT-US-23 backend Gherkin scenarios: forgot password by email with Mailpit. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class ForgotPasswordIT {

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
    private static final Pattern TOKEN = Pattern.compile("set-password\\?token=([A-Za-z0-9_-]+)");

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: Active user requests a password reset link
    @Test
    void activeUserWithPasswordReceivesOneHourResetLink() throws Exception {
        HttpResponse<String> response = forgotPassword("employee1@resolveit.local");

        assertThat(response.statusCode()).isEqualTo(202);
        JsonNode body = json(response);
        assertThat(body.get("message").asString())
                .isEqualTo("If an active account exists for that email, a password reset link has been sent.");

        String token = latestTokenFromEmailTo("employee1@resolveit.local");
        assertThat(token).isNotBlank();

        // Audit check
        assertThat(jdbc.sql("""
                SELECT count(*) FROM identity.user_audit_log
                WHERE action = 'PASSWORD_RESET_REQUESTED' AND new_value = 'employee1@resolveit.local'
                """).query(Integer.class).single()).isGreaterThanOrEqualTo(1);

        // Sets new password using the reset link
        HttpResponse<String> set = setPassword(token, "NewPassword123!");
        assertThat(set.statusCode()).isEqualTo(204);

        // Can log in with the new password
        HttpResponse<String> login = api().logIn("employee1@resolveit.local", "NewPassword123!");
        assertThat(login.statusCode()).isEqualTo(200);
    }

    // Scenario: Resetting password clears login lockout
    @Test
    void resettingPasswordClearsLoginLockout() throws Exception {
        // Trigger 5 failed logins to lock employee2
        for (int i = 0; i < 5; i++) {
            api().logIn("employee2@resolveit.local", "WrongPassword123!");
        }
        HttpResponse<String> locked = api().logIn("employee2@resolveit.local", "WrongPassword123!");
        assertThat(locked.statusCode()).isEqualTo(429);

        // Request reset
        HttpResponse<String> forgot = forgotPassword("employee2@resolveit.local");
        assertThat(forgot.statusCode()).isEqualTo(202);

        String token = latestTokenFromEmailTo("employee2@resolveit.local");
        HttpResponse<String> set = setPassword(token, "UnblockedPassword123!");
        assertThat(set.statusCode()).isEqualTo(204);

        // Can log in immediately (lockout cleared)
        HttpResponse<String> login = api().logIn("employee2@resolveit.local", "UnblockedPassword123!");
        assertThat(login.statusCode()).isEqualTo(200);
    }

    // Scenario: Rate limit of at most 3 reset emails per user per hour
    @Test
    void rateLimitAtMostThreeResetEmailsPerHour() throws Exception {
        clearMailpit();

        // 3 requests allowed
        for (int i = 1; i <= 3; i++) {
            HttpResponse<String> res = forgotPassword("agent1@resolveit.local");
            assertThat(res.statusCode()).isEqualTo(202);
        }

        // 4th request silently ignored
        HttpResponse<String> extra = forgotPassword("agent1@resolveit.local");
        assertThat(extra.statusCode()).isEqualTo(202);

        // Verify only 3 emails sent
        int count = countEmailsTo("agent1@resolveit.local");
        assertThat(count).isEqualTo(3);

        int auditCount = jdbc.sql("""
                SELECT count(*) FROM identity.user_audit_log
                WHERE action = 'PASSWORD_RESET_REQUESTED' AND new_value = 'agent1@resolveit.local'
                """).query(Integer.class).single();
        assertThat(auditCount).isEqualTo(3);
    }

    // Scenario: Unknown email returns 202 without sending email
    @Test
    void unknownEmailReturnsGeneric202WithoutSendingEmail() throws Exception {
        clearMailpit();

        HttpResponse<String> response = forgotPassword("nobody@resolveit.local");
        assertThat(response.statusCode()).isEqualTo(202);
        assertThat(json(response).get("message").asString())
                .isEqualTo("If an active account exists for that email, a password reset link has been sent.");

        assertThat(countEmailsTo("nobody@resolveit.local")).isEqualTo(0);
    }

    // Scenario: CSRF protection is enforced
    @Test
    void forgotPasswordRequiresCsrfToken() throws Exception {
        HttpResponse<String> response = api().send(api().request("/api/v1/auth/password/forgot")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(
                        JSON.writeValueAsString(Map.of("email", "employee1@resolveit.local")))));

        assertThat(response.statusCode()).isEqualTo(403);
        assertThat(json(response).get("code").asString()).isEqualTo("AUTH_CSRF_INVALID");
    }

    private HttpResponse<String> forgotPassword(String email) throws Exception {
        HttpResponse<String> csrf = api().send(api().request("/api/v1/auth/csrf").GET());
        assertThat(csrf.statusCode()).isEqualTo(204);
        String xsrf = AuthApiClient.cookiePair(csrf, "XSRF-TOKEN");
        return api().send(api().request("/api/v1/auth/password/forgot")
                .header("Content-Type", "application/json")
                .header("Cookie", xsrf)
                .header("X-XSRF-TOKEN", xsrf.substring(xsrf.indexOf('=') + 1))
                .POST(HttpRequest.BodyPublishers.ofString(
                        JSON.writeValueAsString(Map.of("email", email)))));
    }

    private HttpResponse<String> setPassword(String token, String newPassword) throws Exception {
        HttpResponse<String> csrf = api().send(api().request("/api/v1/auth/csrf").GET());
        assertThat(csrf.statusCode()).isEqualTo(204);
        String xsrf = AuthApiClient.cookiePair(csrf, "XSRF-TOKEN");
        return api().send(api().request("/api/v1/auth/password/set")
                .header("Content-Type", "application/json")
                .header("Cookie", xsrf)
                .header("X-XSRF-TOKEN", xsrf.substring(xsrf.indexOf('=') + 1))
                .POST(HttpRequest.BodyPublishers.ofString(
                        JSON.writeValueAsString(Map.of("token", token, "newPassword", newPassword)))));
    }

    private static String latestTokenFromEmailTo(String address) throws Exception {
        for (int attempt = 0; attempt < 50; attempt++) {
            for (JsonNode message : mailpit("/api/v1/messages").get("messages")) {
                for (JsonNode to : message.get("To")) {
                    if (address.equals(to.get("Address").asString())) {
                        String text = mailpit("/api/v1/message/" + message.get("ID").asString()).get("Text").asString();
                        Matcher matcher = TOKEN.matcher(text);
                        if (matcher.find()) {
                            return matcher.group(1);
                        }
                    }
                }
            }
            Thread.sleep(100);
        }
        throw new AssertionError("No email to " + address + " in Mailpit");
    }

    private static int countEmailsTo(String address) throws Exception {
        int count = 0;
        JsonNode messages = mailpit("/api/v1/messages").get("messages");
        if (messages != null) {
            for (JsonNode message : messages) {
                for (JsonNode to : message.get("To")) {
                    if (address.equals(to.get("Address").asString())) {
                        count++;
                    }
                }
            }
        }
        return count;
    }

    private static void clearMailpit() throws Exception {
        URI uri = URI.create("http://" + MAILPIT.getHost() + ":" + MAILPIT.getMappedPort(8025) + "/api/v1/messages");
        HttpClient.newHttpClient().send(HttpRequest.newBuilder(uri).DELETE().build(), HttpResponse.BodyHandlers.discarding());
    }

    private static JsonNode mailpit(String path) throws Exception {
        URI uri = URI.create("http://" + MAILPIT.getHost() + ":" + MAILPIT.getMappedPort(8025) + path);
        HttpResponse<String> response = HttpClient.newHttpClient()
                .send(HttpRequest.newBuilder(uri).GET().build(), HttpResponse.BodyHandlers.ofString());
        return JSON.readTree(response.body());
    }

    private AuthApiClient api() {
        return new AuthApiClient(port());
    }

    private int port() {
        return environment.getRequiredProperty("local.server.port", Integer.class);
    }
}
