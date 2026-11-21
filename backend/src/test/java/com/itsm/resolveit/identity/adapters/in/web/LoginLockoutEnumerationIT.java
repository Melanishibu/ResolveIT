package com.itsm.resolveit.identity.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import java.net.http.HttpResponse;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import tools.jackson.databind.JsonNode;

/**
 * Bug AB#180: the login lockout must not reveal whether an email address has an account. Unknown emails,
 * real accounts and inactive accounts get the same responses, also after repeated failures.
 *
 * <p>Each test inserts its own accounts with unique emails (no password yet, like an invited user, so every
 * attempt fails), so it doesn't lock the dev seed users other tests rely on.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
class LoginLockoutEnumerationIT {

    private static final int ATTEMPTS = 6;

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    /** Every email this test touched, so it can leave the shared database as it found it. */
    private final List<String> usedEmails = new ArrayList<>();

    /**
     * Removes the probe users and counter rows again. Other ITs share this Spring context and database
     * (for example {@code ApiSetupIT} expects no users at all), so this test must not leave rows behind.
     */
    @AfterEach
    void removeProbeRows() {
        for (String email : usedEmails) {
            jdbc.sql("DELETE FROM identity.app_user WHERE email = :email").param("email", email).update();
            jdbc.sql("DELETE FROM identity.unknown_email_login_attempt WHERE email = :email")
                    .param("email", email)
                    .update();
        }
    }

    @Test
    void unknownEmailGetsTheSameResponsesAsARealOneAfterFiveFailures() throws Exception {
        String suffix = uniqueSuffix();
        String realAccount = insertAccount("lockout-real-" + suffix + "@resolveit.local", true);
        String unknownEmail = used("lockout-unknown-" + suffix + "@resolveit.local");

        assertSameResponsesForEveryAttempt(realAccount, unknownEmail);
    }

    @Test
    void lockedInactiveAccountAnswersLikeAnUnknownEmail() throws Exception {
        String suffix = uniqueSuffix();
        String inactiveAccount = insertAccount("lockout-inactive-" + suffix + "@resolveit.local", false);
        String unknownEmail = used("lockout-nobody-" + suffix + "@resolveit.local");

        assertSameResponsesForEveryAttempt(inactiveAccount, unknownEmail);
    }

    private void assertSameResponsesForEveryAttempt(String accountEmail, String unknownEmail) throws Exception {
        for (int attempt = 1; attempt <= ATTEMPTS; attempt++) {
            String password = "Wrong-Password-" + attempt;
            HttpResponse<String> forAccount = api().logIn(accountEmail, password);
            HttpResponse<String> forUnknown = api().logIn(unknownEmail, password);

            assertThat(forUnknown.statusCode()).as("status of attempt %d", attempt)
                    .isEqualTo(forAccount.statusCode());
            JsonNode accountProblem = json(forAccount);
            JsonNode unknownProblem = json(forUnknown);
            for (String field : new String[] {"code", "title", "detail", "params"}) {
                assertThat(unknownProblem.get(field)).as("%s of attempt %d", field, attempt)
                        .isEqualTo(accountProblem.get(field));
            }
            int expectedStatus = attempt <= 5 ? 401 : 429;
            assertThat(forAccount.statusCode()).as("status of attempt %d", attempt).isEqualTo(expectedStatus);
        }
    }

    private String used(String email) {
        usedEmails.add(email);
        return email;
    }

    private String insertAccount(String email, boolean active) {
        used(email);
        jdbc.sql("""
                INSERT INTO identity.app_user (id, email, display_name, role, department, password_hash, active)
                VALUES (:id, :email, 'Lockout Probe', 'EMPLOYEE', 'QA', NULL, :active)
                """)
                .param("id", UUID.randomUUID())
                .param("email", email)
                .param("active", active)
                .update();
        return email;
    }

    private static String uniqueSuffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }

    private AuthApiClient api() {
        return new AuthApiClient(environment.getRequiredProperty("local.server.port", Integer.class));
    }
}
