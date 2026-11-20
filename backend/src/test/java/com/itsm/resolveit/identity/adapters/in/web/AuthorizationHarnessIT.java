package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
import com.itsm.resolveit.testsupport.AuthorizationMatrix.Role;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.test.context.TestPropertySource;

/**
 * The reusable authorisation harness in action (RIT-US-05): one check per role per endpoint.
 * Later stories add one {@code @Test} per new endpoint, in the same style.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class AuthorizationHarnessIT {

    @Autowired
    private Environment environment;

    @Test
    void adminOnlyEndpointIsOpenToAdminsOnly() throws Exception {
        matrix().endpoint("GET", "/api/v1/test-probe/admin-only")
                .expect(Role.ADMIN, 200)
                .expect(Role.SUPPORT_AGENT, 403)
                .expect(Role.EMPLOYEE, 403)
                .expectAnonymous(401)
                .verify();
    }

    @Test
    void stateChangingEndpointIsOpenToEveryLoggedInRole() throws Exception {
        matrix().endpoint("POST", "/api/v1/test-probe/state-change")
                .expect(Role.ADMIN, 200)
                .expect(Role.SUPPORT_AGENT, 200)
                .expect(Role.EMPLOYEE, 200)
                .expectAnonymous(401)
                .verify();
    }

    @Test
    void currentUserEndpointNeedsASession() throws Exception {
        matrix().endpoint("GET", "/api/v1/auth/me")
                .expect(Role.ADMIN, 200)
                .expect(Role.SUPPORT_AGENT, 200)
                .expect(Role.EMPLOYEE, 200)
                .expectAnonymous(401)
                .verify();
    }

    private AuthorizationMatrix matrix() {
        return new AuthorizationMatrix(environment.getRequiredProperty("local.server.port", Integer.class));
    }
}
