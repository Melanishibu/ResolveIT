package com.itsm.resolveit.identity.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
import com.itsm.resolveit.testsupport.AuthApiClient;
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

/** RIT-US-05 (AB#14) backend Gherkin scenarios against the running backend and PostgreSQL 17. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class RequestProtectionIT {

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: Unauthenticated request is rejected
    @Test
    void unauthenticatedRequestIsRejected() throws Exception {
        HttpResponse<String> response = api().me(null);

        assertThat(response.statusCode()).isEqualTo(401);
        assertThat(json(response).get("code").asString()).isEqualTo("AUTH_UNAUTHENTICATED");
        assertThat(matrix().endpoint("GET", "/api/v1/test-probe/admin-only").send(null).statusCode()).isEqualTo(401);
    }

    // Scenario: Forbidden request is rejected
    @Test
    void forbiddenRequestIsRejected() throws Exception {
        Session employee = matrix().logIn(Role.EMPLOYEE);

        HttpResponse<String> response = matrix().endpoint("GET", "/api/v1/test-probe/admin-only").send(employee);

        assertThat(response.statusCode()).isEqualTo(403);
        assertThat(json(response).get("code").asString()).isEqualTo("AUTH_FORBIDDEN");
    }

    // Scenario: State-changing request without CSRF token is rejected
    @Test
    void stateChangingRequestWithoutCsrfTokenIsRejected() throws Exception {
        Session agent = matrix().logIn(Role.SUPPORT_AGENT);

        HttpResponse<String> withoutHeader = api().send(api().request("/api/v1/test-probe/state-change")
                .header("Cookie", agent.cookieHeader())
                .POST(HttpRequest.BodyPublishers.noBody()));
        HttpResponse<String> wrongHeader = api().send(api().request("/api/v1/test-probe/state-change")
                .header("Cookie", agent.cookieHeader())
                .header("X-XSRF-TOKEN", "not-the-token")
                .POST(HttpRequest.BodyPublishers.noBody()));
        HttpResponse<String> withToken = matrix().endpoint("POST", "/api/v1/test-probe/state-change").send(agent);

        for (HttpResponse<String> refused : java.util.List.of(withoutHeader, wrongHeader)) {
            assertThat(refused.statusCode()).isEqualTo(403);
            assertThat(json(refused).get("code").asString()).isEqualTo("AUTH_CSRF_INVALID");
        }
        assertThat(withToken.statusCode()).isEqualTo(200);
    }

    // Scenario: Cross-origin request from an unknown origin is refused
    @Test
    void crossOriginRequestFromAnUnknownOriginIsRefused() throws Exception {
        HttpResponse<String> preflight = api().send(api().request("/api/v1/auth/me")
                .header("Origin", "https://evil.example")
                .header("Access-Control-Request-Method", "GET")
                .method("OPTIONS", HttpRequest.BodyPublishers.noBody()));

        assertThat(preflight.statusCode()).isEqualTo(403);
        assertThat(preflight.headers().firstValue("Access-Control-Allow-Origin")).isEmpty();
    }

    // Scenario: Deactivated user loses access
    @Test
    void deactivatedUserLosesAccess() throws Exception {
        UUID agentId = UUID.randomUUID();
        jdbc.sql("""
                INSERT INTO identity.app_user (id, email, display_name, role, password_hash, active, department)
                SELECT :id, 'agent-to-deactivate@resolveit.local', 'Agent Three', 'SUPPORT_AGENT', password_hash, TRUE,
                       'IT Support'
                FROM identity.app_user WHERE email = 'agent1@resolveit.local'
                """).param("id", agentId).update();
        HttpResponse<String> login = api().logIn("agent-to-deactivate@resolveit.local", AuthApiClient.PASSWORD);
        String session = AuthApiClient.cookiePair(login, SessionCookies.SESSION_COOKIE);
        assertThat(api().me(session).statusCode()).isEqualTo(200);

        // The Admin deactivates the Agent (the user-management screen arrives in RIT-US-10).
        jdbc.sql("UPDATE identity.app_user SET active = FALSE WHERE id = :id").param("id", agentId).update();

        HttpResponse<String> next = api().me(session);
        assertThat(next.statusCode()).isEqualTo(401);
        assertThat(json(next).get("code").asString()).isEqualTo("AUTH_UNAUTHENTICATED");
    }

    private AuthApiClient api() {
        return new AuthApiClient(port());
    }

    private AuthorizationMatrix matrix() {
        return new AuthorizationMatrix(port());
    }

    private int port() {
        return environment.getRequiredProperty("local.server.port", Integer.class);
    }
}
