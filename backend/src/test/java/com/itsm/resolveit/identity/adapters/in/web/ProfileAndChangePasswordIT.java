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
import tools.jackson.databind.json.JsonMapper;

/**
 * RIT-US-27 backend Gherkin scenarios for My Profile and Change Password.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class ProfileAndChangePasswordIT {

    private static final String DEV_PASSWORD = "ResolveIT-Dev-2026";
    private static final JsonMapper JSON = JsonMapper.builder().build();

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: User sees their profile
    @Test
    void userSeesTheirProfile() throws Exception {
        Session session = matrix().logIn(Role.EMPLOYEE);

        HttpResponse<String> response = get(session, "/api/v1/users/me");

        assertThat(response.statusCode()).isEqualTo(200);
        JsonNode body = json(response);
        assertThat(body.get("name").asString()).isEqualTo("Employee One");
        assertThat(body.get("email").asString()).isEqualTo("employee1@resolveit.local");
        assertThat(body.get("role").asString()).isEqualTo("EMPLOYEE");
        assertThat(body.get("roleLabel").asString()).isEqualTo("Employee");
        assertThat(body.get("department").asString()).isEqualTo("Finance");
        assertThat(body.get("memberSince").asString()).isNotBlank();
    }

    // Scenario: User changes their password
    @Test
    void userChangesTheirPassword() throws Exception {
        String email = "changepw-test-" + UUID.randomUUID() + "@resolveit.local";
        String userId = UUID.randomUUID().toString();
        insertTestUser(userId, email, "Pass-Test-1234");

        try {
            Session session = logIn(email, "Pass-Test-1234");
            String newPassword = "NewValidPassword-9876";

            HttpResponse<String> changeResponse = postJson(session, "/api/v1/auth/password/change",
                    Map.of("currentPassword", "Pass-Test-1234", "newPassword", newPassword));
            assertThat(changeResponse.statusCode()).isEqualTo(204);

            // Verify PASSWORD_CHANGED was recorded in audit log
            Long auditCount = jdbc.sql("SELECT count(*) FROM identity.user_audit_log WHERE user_id = CAST(:id AS uuid) AND action = 'PASSWORD_CHANGED'")
                    .param("id", userId)
                    .query(Long.class)
                    .single();
            assertThat(auditCount).isGreaterThanOrEqualTo(1);

            // And they can log in with the new password and not with the old one
            HttpResponse<String> loginOld = api().logIn(email, "Pass-Test-1234");
            assertThat(loginOld.statusCode()).isEqualTo(401);

            HttpResponse<String> loginNew = api().logIn(email, newPassword);
            assertThat(loginNew.statusCode()).isEqualTo(200);
        } finally {
            deleteTestUser(userId);
        }
    }

    // Scenario: Wrong current password
    @Test
    void wrongCurrentPassword() throws Exception {
        String email = "wrongpw-test-" + UUID.randomUUID() + "@resolveit.local";
        String userId = UUID.randomUUID().toString();
        insertTestUser(userId, email, "Pass-Test-1234");

        try {
            Session session = logIn(email, "Pass-Test-1234");
            HttpResponse<String> response = postJson(session, "/api/v1/auth/password/change",
                    Map.of("currentPassword", "WrongPassword-9999", "newPassword", "NewValidPassword-9876"));

            assertThat(response.statusCode()).isEqualTo(400);
            assertThat(json(response).get("code").asString()).isEqualTo("AUTH_CURRENT_PASSWORD_WRONG");
        } finally {
            deleteTestUser(userId);
        }
    }

    // Scenario: New password must follow the policy
    @Test
    void newPasswordMustFollowPolicy() throws Exception {
        String email = "policy-test-" + UUID.randomUUID() + "@resolveit.local";
        String userId = UUID.randomUUID().toString();
        insertTestUser(userId, email, "Pass-Test-1234");

        try {
            Session session = logIn(email, "Pass-Test-1234");
            HttpResponse<String> response = postJson(session, "/api/v1/auth/password/change",
                    Map.of("currentPassword", "Pass-Test-1234", "newPassword", "abc"));

            assertThat(response.statusCode()).isEqualTo(400);
            assertThat(json(response).get("code").asString()).isEqualTo("PASSWORD_POLICY_VIOLATION");
        } finally {
            deleteTestUser(userId);
        }
    }

    // Scenario: New password must differ from the current one
    @Test
    void newPasswordMustDifferFromCurrentOne() throws Exception {
        String email = "samepw-test-" + UUID.randomUUID() + "@resolveit.local";
        String userId = UUID.randomUUID().toString();
        insertTestUser(userId, email, "Pass-Test-1234");

        try {
            Session session = logIn(email, "Pass-Test-1234");
            HttpResponse<String> response = postJson(session, "/api/v1/auth/password/change",
                    Map.of("currentPassword", "Pass-Test-1234", "newPassword", "Pass-Test-1234"));

            assertThat(response.statusCode()).isEqualTo(400);
            assertThat(json(response).get("code").asString()).isEqualTo("PASSWORD_SAME_AS_CURRENT");
        } finally {
            deleteTestUser(userId);
        }
    }

    // Scenario: Other sessions end after a password change
    @Test
    void otherSessionsEndAfterPasswordChange() throws Exception {
        String email = "multisess-test-" + UUID.randomUUID() + "@resolveit.local";
        String userId = UUID.randomUUID().toString();
        insertTestUser(userId, email, "Pass-Test-1234");

        try {
            // Given the user is logged in on two browsers
            Session browser1 = logIn(email, "Pass-Test-1234");
            Session browser2 = logIn(email, "Pass-Test-1234");

            // When they change the password in one of them
            HttpResponse<String> change = postJson(browser1, "/api/v1/auth/password/change",
                    Map.of("currentPassword", "Pass-Test-1234", "newPassword", "NewValidPassword-9876"));
            assertThat(change.statusCode()).isEqualTo(204);

            // Then the other browser's next request returns 401
            HttpResponse<String> otherNext = get(browser2, "/api/v1/users/me");
            assertThat(otherNext.statusCode()).isEqualTo(401);

            // And the current browser's next request still succeeds
            HttpResponse<String> currentNext = get(browser1, "/api/v1/users/me");
            assertThat(currentNext.statusCode()).isEqualTo(200);
        } finally {
            deleteTestUser(userId);
        }
    }

    private Session logIn(String email, String password) throws Exception {
        HttpResponse<String> login = api().logIn(email, password);
        assertThat(login.statusCode()).as("login as %s", email).isEqualTo(200);
        String session = AuthApiClient.cookiePair(login, "RIT_SESSION");
        String xsrf = AuthApiClient.cookiePair(login, "XSRF-TOKEN");
        return new Session(session + "; " + xsrf, xsrf.substring(xsrf.indexOf('=') + 1));
    }

    private void insertTestUser(String userId, String email, String password) {
        // BCrypt hash of password (cost 10): $2a$10$vdxq/oWjuLrsVHtlSFeOk.kkJkbEN3UjE2aMDNauexaXvVsnVtv3u is hash for ResolveIT-Dev-2026
        // For custom password, we can generate with BCryptPasswordEncoder
        org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder encoder =
                new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder(10);
        String hash = encoder.encode(password);

        jdbc.sql("""
                INSERT INTO identity.app_user (id, email, display_name, role, password_hash, active, department)
                VALUES (CAST(:id AS uuid), :email, 'Test User', 'EMPLOYEE', :hash, TRUE, 'Engineering')
                """)
                .param("id", userId).param("email", email).param("hash", hash)
                .update();
    }

    private void deleteTestUser(String userId) {
        jdbc.sql("DELETE FROM identity.user_session WHERE user_id = CAST(:id AS uuid)")
                .param("id", userId).update();
        jdbc.sql("DELETE FROM identity.app_user WHERE id = CAST(:id AS uuid)")
                .param("id", userId).update();
    }

    private HttpResponse<String> get(Session session, String path) throws Exception {
        return api().send(api().request(path).GET().header("Cookie", session.cookieHeader()));
    }

    private HttpResponse<String> postJson(Session session, String path, Map<String, Object> body) throws Exception {
        HttpRequest.Builder request = api().request(path)
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader())
                .header("X-XSRF-TOKEN", session.xsrfToken())
                .POST(HttpRequest.BodyPublishers.ofString(JSON.writeValueAsString(body)));
        return api().send(request);
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
