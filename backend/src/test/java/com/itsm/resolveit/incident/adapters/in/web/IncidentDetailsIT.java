package com.itsm.resolveit.incident.adapters.in.web;

import static com.itsm.resolveit.testsupport.AuthApiClient.json;
import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import com.itsm.resolveit.testsupport.AuthorizationMatrix;
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
import tools.jackson.databind.JsonNode;

/** RIT-US-10 (AB#38) backend Gherkin scenarios over real HTTP and PostgreSQL. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed")
class IncidentDetailsIT {

    private static final String EMPLOYEE_TWO = "00000000-0000-4000-8000-000000000005";

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    // Scenario: Employee opens their own incident
    @Test
    void employeeOpensTheirOwnIncident() throws Exception {
        Session employee = matrix().logIn(Role.EMPLOYEE);
        String id = reportIncident(employee);

        HttpResponse<String> response = get(employee.cookieHeader(), id);

        assertThat(response.statusCode()).isEqualTo(200);
        JsonNode body = json(response);
        assertThat(body.get("status").asString()).isEqualTo("OPEN");
        assertThat(body.get("ticketNumber").asString()).matches("INC-\\d{4}-\\d{5}");
        assertThat(body.get("title").asString()).isEqualTo("Printer jams");
        assertThat(body.get("category").asString()).isEqualTo("HARDWARE");
        assertThat(body.get("priority").asString()).isEqualTo("LOW");
        assertThat(body.get("createdBy").get("name").asString()).isEqualTo("Employee One");
        assertThat(body.get("assignee").isNull()).isTrue();
        assertThat(body.get("allowedActions")).isEmpty();
    }

    // Scenario: TC-015 Employee cannot open another employee's incident
    @Test
    void tc015EmployeeCannotOpenAnotherEmployeesIncident() throws Exception {
        // employee2 is locked by AuthLoginIT in this shared database, so the incident is moved to employee2
        // and employee1 asks for it: the same rule from the other side.
        Session employee1 = matrix().logIn(Role.EMPLOYEE);
        String id = reportIncident(employee1);
        jdbc.sql("UPDATE incident.incident SET created_by = :other WHERE id = :id")
                .param("other", UUID.fromString(EMPLOYEE_TWO)).param("id", UUID.fromString(id)).update();

        HttpResponse<String> response = get(employee1.cookieHeader(), id);

        assertThat(response.statusCode()).isEqualTo(403);
        assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_ACCESS_DENIED");
    }

    // Scenario: Unknown incident
    @Test
    void unknownIncident() throws Exception {
        Session admin = matrix().logIn(Role.ADMIN);

        for (String id : new String[] {UUID.randomUUID().toString(), "not-an-id"}) {
            HttpResponse<String> response = get(admin.cookieHeader(), id);
            assertThat(response.statusCode()).as(id).isEqualTo(404);
            assertThat(json(response).get("code").asString()).isEqualTo("INCIDENT_NOT_FOUND");
        }
    }

    // Scenario: Actions follow the permission table
    @Test
    void actionsFollowThePermissionTable() throws Exception {
        Session employee = matrix().logIn(Role.EMPLOYEE);
        String id = reportIncident(employee);
        jdbc.sql("UPDATE incident.incident SET status = 'RESOLVED' WHERE id = :id").param("id", UUID.fromString(id))
                .update();

        JsonNode body = json(get(employee.cookieHeader(), id));

        assertThat(body.get("allowedActions").toString()).isEqualTo("[\"REOPEN\",\"CLOSE\"]");
    }

    // Scenario: Reporter's department is shown
    @Test
    void reportersDepartmentIsShown() throws Exception {
        String id = reportIncident(matrix().logIn(Role.EMPLOYEE));

        JsonNode body = json(get(matrix().logIn(Role.ADMIN).cookieHeader(), id));

        assertThat(body.get("createdBy").get("department").asString()).isEqualTo("Finance");
    }

    private String reportIncident(Session session) throws Exception {
        HttpResponse<String> created = api().send(api().request("/api/v1/tickets")
                .header("Content-Type", "application/json")
                .header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken())
                .POST(HttpRequest.BodyPublishers.ofString(
                        "{\"title\":\"Printer jams\",\"description\":\"Paper jam on floor 2\","
                                + "\"category\":\"HARDWARE\",\"priority\":\"LOW\"}")));
        assertThat(created.statusCode()).isEqualTo(201);
        return json(created).get("id").asString();
    }

    private HttpResponse<String> get(String cookieHeader, String id) throws Exception {
        return api().send(api().request("/api/v1/tickets/" + id).GET().header("Cookie", cookieHeader));
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
