package com.itsm.resolveit.identity.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.identity.domain.model.InvitationToken;
import com.itsm.resolveit.testsupport.AuthApiClient;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Role;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Session;
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

/** RIT-US-07 (AB#49) backend Gherkin scenarios: the link comes from a real email in Mailpit. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class SetPasswordIT {

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
    private static final Pattern TOKEN = Pattern.compile("set-password\\?token=([A-Za-z0-9_-]+)");

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: User sets a password from a valid link
    @Test
    void userSetsAPasswordFromAValidLink() throws Exception {
        String userId = invite("Asha Rao", "asha@resolveit.local");
        String token = tokenFromEmailTo("asha@resolveit.local");

        HttpResponse<String> set = setPassword(token, "Welcome2026Asha");

        assertThat(set.statusCode()).isEqualTo(204);
        assertThat(api().logIn("asha@resolveit.local", "Welcome2026Asha").statusCode())
                .as("she can log in with that password").isEqualTo(200);
        assertThat(jdbc.sql("""
                SELECT count(*) FROM identity.user_audit_log
                WHERE user_id = :id::uuid AND actor_id = :id::uuid AND action = 'PASSWORD_SET'""")
                .param("id", userId).query(Integer.class).single()).isEqualTo(1);
        assertThat(jdbc.sql("SELECT status FROM identity.invitation WHERE user_id = :id::uuid")
                .param("id", userId).query(String.class).single()).isEqualTo("USED");
    }

    // Scenario: Link works only once
    @Test
    void linkWorksOnlyOnce() throws Exception {
        invite("Ravi Kumar", "ravi@resolveit.local");
        String token = tokenFromEmailTo("ravi@resolveit.local");
        assertThat(setPassword(token, "FirstChoice2026").statusCode()).isEqualTo(204);

        HttpResponse<String> again = setPassword(token, "SecondChoice2026");

        assertThat(again.statusCode()).isEqualTo(400);
        assertThat(json(again).get("code").asString()).isEqualTo("AUTH_TOKEN_INVALID");
        assertThat(api().logIn("ravi@resolveit.local", "FirstChoice2026").statusCode())
                .as("the first password stays").isEqualTo(200);
        HttpResponse<String> unknown = setPassword("never-issued-token", "Whatever2026xx");
        assertThat(unknown.statusCode()).as("unknown token").isEqualTo(400);
        assertThat(json(unknown).get("code").asString()).isEqualTo("AUTH_TOKEN_INVALID");
    }

    // Scenario: Expired link is rejected
    @Test
    void expiredLinkIsRejected() throws Exception {
        String userId = invite("Mira Shah", "mira@resolveit.local");
        InvitationToken old = InvitationToken.generate();
        jdbc.sql("""
                INSERT INTO identity.invitation (id, user_id, token_hash, created_at, expires_at, status)
                VALUES (gen_random_uuid(), :userId::uuid, :hash, now() - interval '25 hours',
                        now() - interval '1 hour', 'SENT')""")
                .param("userId", userId).param("hash", old.hash()).update();

        HttpResponse<String> response = setPassword(old.value(), "Welcome2026Mira");

        assertThat(response.statusCode()).isEqualTo(400);
        JsonNode problem = json(response);
        assertThat(problem.get("code").asString()).isEqualTo("AUTH_TOKEN_EXPIRED");
        assertThat(problem.get("title").asString()).isEqualTo("This link has expired");
    }

    // Scenario: Weak password is rejected
    @Test
    void weakPasswordIsRejected() throws Exception {
        invite("Leo Park", "leo@resolveit.local");
        String token = tokenFromEmailTo("leo@resolveit.local");

        HttpResponse<String> weak = setPassword(token, "short1");

        assertThat(weak.statusCode()).isEqualTo(400);
        JsonNode problem = json(weak);
        assertThat(problem.get("code").asString()).isEqualTo("PASSWORD_POLICY_VIOLATION");
        assertThat(problem.get("detail").asString()).contains("12 to 128 characters");
        assertThat(setPassword(token, "LeoPark2026Ok").statusCode())
                .as("a refused password does not use up the link").isEqualTo(204);
    }

    @Test
    void settingAPasswordNeedsTheCsrfToken() throws Exception {
        HttpResponse<String> response = api().send(api().request("/api/v1/auth/password/set")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(
                        JSON.writeValueAsString(Map.of("token", "x", "newPassword", "Whatever2026xx")))));

        assertThat(response.statusCode()).isEqualTo(403);
        assertThat(json(response).get("code").asString()).isEqualTo("AUTH_CSRF_INVALID");
    }

    /** As a logged-out browser would: fetch the CSRF cookie, then send it back with the header. */
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

    private String invite(String name, String email) throws Exception {
        Session admin = new AuthorizationMatrix(port()).logIn(Role.ADMIN);
        HttpResponse<String> created = api().send(api().request("/api/v1/users")
                .header("Content-Type", "application/json")
                .header("Cookie", admin.cookieHeader()).header("X-XSRF-TOKEN", admin.xsrfToken())
                .POST(HttpRequest.BodyPublishers.ofString(JSON.writeValueAsString(
                        Map.of("name", name, "email", email, "role", "EMPLOYEE", "department", "Finance")))));
        assertThat(created.statusCode()).as(created.body()).isEqualTo(201);
        return json(created).get("id").asString();
    }

    private static String tokenFromEmailTo(String address) throws Exception {
        for (int attempt = 0; attempt < 50; attempt++) {
            for (JsonNode message : mailpit("/api/v1/messages").get("messages")) {
                for (JsonNode to : message.get("To")) {
                    if (address.equals(to.get("Address").asString())) {
                        String text = mailpit("/api/v1/message/" + message.get("ID").asString()).get("Text").asString();
                        Matcher matcher = TOKEN.matcher(text);
                        assertThat(matcher.find()).as("link in the email").isTrue();
                        return matcher.group(1);
                    }
                }
            }
            Thread.sleep(100); // the email is sent after the commit
        }
        throw new AssertionError("No email to " + address + " in Mailpit");
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
