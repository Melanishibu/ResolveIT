package com.itsm.resolveit.identity.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.PASSWORD;
import static com.itsm.resolveit.testsupport.AuthApiClient.cookiePair;
import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static com.itsm.resolveit.testsupport.AuthApiClient.setCookie;
import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.test.context.TestPropertySource;
import tools.jackson.databind.JsonNode;

/**
 * RIT-US-04 (AB#13) Gherkin scenarios against the running backend and PostgreSQL 17.
 *
 * <p>Uses the dev seed users: this test adds the dev-only seed location, exactly as the dev profile
 * does. Each scenario uses its own seed user, so the scenarios don't affect each other.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class AuthLoginIT {

    @Autowired
    private Environment environment;

    // Scenario: TC-001 Login with valid credentials
    @Test
    void tc001LoginWithValidCredentials() throws Exception {
        HttpResponse<String> response = api().logIn("employee1@resolveit.local", PASSWORD);

        assertThat(response.statusCode()).isEqualTo(200);
        JsonNode body = json(response);
        assertThat(body.get("name").asString()).isEqualTo("Employee One");
        assertThat(body.get("role").asString()).isEqualTo("EMPLOYEE");
        assertThat(body.get("email").asString()).isEqualTo("employee1@resolveit.local");
        assertThat(body.get("id").asString()).isEqualTo("00000000-0000-4000-8000-000000000004");
        assertThat(body.has("passwordHash")).isFalse();
        assertThat(setCookie(response, "RIT_SESSION")).isPresent();
        assertThat(setCookie(response, "XSRF-TOKEN")).isPresent();

        HttpResponse<String> me = api().me(cookiePair(response, "RIT_SESSION"));
        assertThat(me.statusCode()).isEqualTo(200);
        assertThat(json(me).get("name").asString()).isEqualTo("Employee One");
    }

    // Scenario: TC-002 Login with invalid credentials
    @Test
    void tc002LoginWithInvalidCredentials() throws Exception {
        HttpResponse<String> wrongPassword = api().logIn("admin@resolveit.local", "Wrong-Password-1");
        HttpResponse<String> unknownEmail = api().logIn("nobody@resolveit.local", PASSWORD);

        for (HttpResponse<String> response : java.util.List.of(wrongPassword, unknownEmail)) {
            assertThat(response.statusCode()).isEqualTo(401);
            JsonNode problem = json(response);
            assertThat(problem.get("code").asString()).isEqualTo("AUTH_INVALID_CREDENTIALS");
            assertThat(problem.get("title").asString()).isEqualTo("Email or password is incorrect");
            assertThat(setCookie(response, "RIT_SESSION")).isEmpty();
        }
        assertThat(json(wrongPassword).get("detail").asString())
                .as("the same message for both cases, so it never says which part was wrong")
                .isEqualTo(json(unknownEmail).get("detail").asString());
    }

    // Scenario: Email and password are mandatory (backend side: the API refuses a request without them)
    @Test
    void emailAndPasswordAreMandatory() throws Exception {
        HttpResponse<String> response = api().logIn("", null);

        assertThat(response.statusCode()).isEqualTo(400);
        JsonNode problem = json(response);
        assertThat(problem.get("code").asString()).isEqualTo("VALIDATION_FAILED");
        assertThat(problem.get("params").get("fields").toString()).contains("email", "password");
    }

    // Scenario: Inactive user cannot log in
    @Test
    void inactiveUserCannotLogIn() throws Exception {
        HttpResponse<String> response = api().logIn("agent2@resolveit.local", PASSWORD);

        assertThat(response.statusCode()).isEqualTo(401);
        assertThat(json(response).get("code").asString()).isEqualTo("AUTH_INVALID_CREDENTIALS");
        assertThat(setCookie(response, "RIT_SESSION")).isEmpty();
    }

    // Scenario: Account is locked after five failures
    @Test
    void accountIsLockedAfterFiveFailures() throws Exception {
        for (int attempt = 1; attempt <= 5; attempt++) {
            assertThat(api().logIn("employee2@resolveit.local", "Wrong-Password-" + attempt).statusCode())
                    .as("failed attempt %d", attempt)
                    .isEqualTo(401);
        }

        HttpResponse<String> response = api().logIn("employee2@resolveit.local", PASSWORD);

        assertThat(response.statusCode()).isEqualTo(429);
        JsonNode problem = json(response);
        assertThat(problem.get("code").asString()).isEqualTo("AUTH_LOGIN_TEMPORARILY_BLOCKED");
        assertThat(problem.get("params").get("retryAfterMinutes").asInt()).isBetween(14, 15);
        assertThat(setCookie(response, "RIT_SESSION")).isEmpty();
    }

    // Scenario: Logout ends the session
    @Test
    void logoutEndsTheSession() throws Exception {
        HttpResponse<String> login = api().logIn("agent1@resolveit.local", PASSWORD);
        String session = cookiePair(login, "RIT_SESSION");
        String xsrf = cookiePair(login, "XSRF-TOKEN");
        assertThat(api().me(session).statusCode()).isEqualTo(200);

        // AB#14: logout is state-changing, so it carries the CSRF token like the frontend does.
        HttpResponse<String> logout = api().send(api().request("/api/v1/auth/logout")
                .header("Cookie", session + "; " + xsrf)
                .header("X-XSRF-TOKEN", xsrf.substring(xsrf.indexOf('=') + 1))
                .POST(java.net.http.HttpRequest.BodyPublishers.noBody()));

        assertThat(logout.statusCode()).isEqualTo(204);
        assertThat(setCookie(logout, "RIT_SESSION")).hasValueSatisfying(cookie -> assertThat(cookie).contains("Max-Age=0"));
        assertThat(setCookie(logout, "XSRF-TOKEN")).hasValueSatisfying(cookie -> assertThat(cookie).contains("Max-Age=0"));
        HttpResponse<String> meWithoutCookie = api().me(null);
        assertThat(meWithoutCookie.statusCode()).isEqualTo(401);
        assertThat(json(meWithoutCookie).get("code").asString()).isEqualTo("AUTH_UNAUTHENTICATED");
        HttpResponse<String> meWithOldCookie = api().me(session);
        assertThat(meWithOldCookie.statusCode()).as("a token kept after logout no longer works").isEqualTo(401);
        assertThat(json(meWithOldCookie).get("code").asString()).isEqualTo("AUTH_UNAUTHENTICATED");
    }

    // Scenario: Session cookie is protected
    @Test
    void sessionCookieIsProtected() throws Exception {
        HttpResponse<String> response = api().logIn("admin@resolveit.local", PASSWORD);

        assertThat(setCookie(response, "RIT_SESSION")).hasValueSatisfying(cookie -> assertThat(cookie)
                .contains("HttpOnly")
                .contains("Secure")
                .contains("SameSite=Strict")
                .contains("Path=/")
                .contains("Max-Age=28800"));
        assertThat(setCookie(response, "XSRF-TOKEN")).hasValueSatisfying(cookie -> assertThat(cookie)
                .as("the frontend must read the XSRF token, so it is not HttpOnly")
                .doesNotContain("HttpOnly")
                .contains("Secure")
                .contains("SameSite=Strict"));
    }

    private AuthApiClient api() {
        return new AuthApiClient(environment.getRequiredProperty("local.server.port", Integer.class));
    }
}
