package com.itsm.resolveit.shared.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
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
import org.springframework.test.context.TestPropertySource;
import tools.jackson.databind.JsonNode;

/**
 * Bug AB#186: request input the server cannot read (a parameter of the wrong type, a body that is not JSON or
 * has a field of the wrong type) is a client error: 400 VALIDATION_FAILED naming the field, never 500.
 *
 * <p>Every request here is refused before any data changes, so the shared seed users stay untouched.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class BadRequestInputIT {

    private static final String AGENT1_ID = "00000000-0000-4000-8000-000000000002";

    @Autowired
    private Environment environment;

    @Test
    void aQueryParameterOfTheWrongTypeIsAValidationError() throws Exception {
        Session admin = matrix().logIn(Role.ADMIN);

        HttpResponse<String> response = api().send(api().request("/api/v1/users?page=abc").GET()
                .header("Cookie", admin.cookieHeader()));

        assertValidationFailed(response, "page");
    }

    @Test
    void aPathParameterOfTheWrongTypeIsAValidationError() throws Exception {
        HttpResponse<String> response = patch(matrix().logIn(Role.ADMIN), "/api/v1/users/not-a-uuid/status",
                "{\"active\":false}");

        assertValidationFailed(response, "id");
    }

    @Test
    void aBodyThatIsNotJsonIsAValidationError() throws Exception {
        HttpResponse<String> response = patch(matrix().logIn(Role.ADMIN), "/api/v1/users/" + AGENT1_ID + "/status",
                "{\"active\":");

        assertThat(response.statusCode()).isEqualTo(400);
        assertThat(json(response).get("code").asString()).isEqualTo("VALIDATION_FAILED");
    }

    @Test
    void aBodyFieldOfTheWrongTypeIsAValidationError() throws Exception {
        HttpResponse<String> response = patch(matrix().logIn(Role.ADMIN), "/api/v1/users/" + AGENT1_ID + "/status",
                "{\"active\":\"maybe\"}");

        assertValidationFailed(response, "active");
        assertThat(response.body()).as("the raw input is never echoed").doesNotContain("maybe");
    }

    @Test
    void aMalformedIncidentBodyIsAValidationError() throws Exception {
        Session employee = matrix().logIn(Role.EMPLOYEE);

        HttpResponse<String> response = api().send(api().request("/api/v1/tickets")
                .header("Content-Type", "application/json")
                .header("Cookie", employee.cookieHeader()).header("X-XSRF-TOKEN", employee.xsrfToken())
                .POST(HttpRequest.BodyPublishers.ofString("{\"title\":")));

        assertThat(response.statusCode()).isEqualTo(400);
        assertThat(json(response).get("code").asString()).isEqualTo("VALIDATION_FAILED");
    }

    private static void assertValidationFailed(HttpResponse<String> response, String field) {
        assertThat(response.statusCode()).as(response.body()).isEqualTo(400);
        JsonNode problem = json(response);
        assertThat(problem.get("code").asString()).isEqualTo("VALIDATION_FAILED");
        assertThat(problem.get("params").get("fields").toString()).contains("\"" + field + "\"");
    }

    private HttpResponse<String> patch(Session session, String path, String body) throws Exception {
        return api().send(api().request(path)
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .method("PATCH", HttpRequest.BodyPublishers.ofString(body)));
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
