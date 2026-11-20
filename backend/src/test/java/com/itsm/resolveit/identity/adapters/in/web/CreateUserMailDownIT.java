package com.itsm.resolveit.identity.adapters.in.web;

import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Role;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Session;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.TestPropertySource;

/**
 * RIT-US-06: the test profile has no mail server (SMTP on a closed port), like a mail server that is down.
 * Same context as the other dev-seed ITs.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class CreateUserMailDownIT {

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: Mail server down does not lose the user
    @Test
    void mailServerDownDoesNotLoseTheUser() throws Exception {
        int port = environment.getRequiredProperty("local.server.port", Integer.class);
        Session admin = new AuthorizationMatrix(port).logIn(Role.ADMIN);
        AuthApiClient api = new AuthApiClient(port);

        HttpResponse<String> response = api.send(api.request("/api/v1/users")
                .header("Content-Type", "application/json")
                .header("Cookie", admin.cookieHeader())
                .header("X-XSRF-TOKEN", admin.xsrfToken())
                .POST(HttpRequest.BodyPublishers.ofString("""
                        {"name": "Mail Down", "email": "maildown@resolveit.local", "role": "EMPLOYEE",
                         "department": "Finance"}""")));

        assertThat(response.statusCode()).isEqualTo(201);
        assertThat(jdbc.sql("SELECT active FROM identity.app_user WHERE email = 'maildown@resolveit.local'")
                .query(Boolean.class).single()).isTrue();
        assertThat(jdbc.sql("""
                SELECT i.status FROM identity.invitation i JOIN identity.app_user u ON u.id = i.user_id
                WHERE u.email = 'maildown@resolveit.local'""").query(String.class).single()).isEqualTo("SEND_FAILED");
    }
}
