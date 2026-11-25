package com.itsm.resolveit;

import static org.assertj.core.api.Assertions.assertThat;

import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import tools.jackson.databind.JsonNode;

/** Scenario: Backend starts against local PostgreSQL (PostgreSQL 17 provided by Testcontainers). */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
class BackendStartupIT {

    @Autowired
    private Environment environment;

    @Test
    void backendStartsAgainstLocalPostgresql() throws Exception {
        HttpResponse<String> response = client().send("GET", "/api/v1/health");

        assertThat(response.statusCode()).isEqualTo(200);
        JsonNode body = HttpTestClient.json(response);
        assertThat(body.get("status").asString()).isEqualTo("UP");
        assertThat(body.has("components")).as("health details are never shown").isFalse();
        assertThat(body.has("details")).as("health details are never shown").isFalse();
    }

    @Test
    void testsNeverActivateTheDevProfile() {
        assertThat(environment.getActiveProfiles()).contains("test").doesNotContain("dev");
    }

    @Test
    void openApiDocumentationIsPublishedAtApiDocs() throws Exception {
        HttpResponse<String> response = client().send("GET", "/api/docs");

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(HttpTestClient.json(response).has("openapi")).isTrue();
    }

    private HttpTestClient client() {
        return new HttpTestClient(environment.getRequiredProperty("local.server.port", Integer.class));
    }
}
