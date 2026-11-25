package com.itsm.resolveit.shared.adapters.in.web;

import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.HttpTestClient;
import com.itsm.resolveit.TestcontainersConfiguration;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import tools.jackson.databind.JsonNode;

/** Scenario: Errors are returned as Problem Details. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
class ProblemDetailsIT {

    @Autowired
    private Environment environment;

    @Test
    void errorsAreReturnedAsProblemDetails() throws Exception {
        HttpResponse<String> response = client().send("GET", "/api/v1/does-not-exist");

        assertThat(response.statusCode()).isEqualTo(404);
        assertThat(response.headers().firstValue("Content-Type")).hasValueSatisfying(
                contentType -> assertThat(contentType).startsWith("application/problem+json"));
        JsonNode body = HttpTestClient.json(response);
        assertThat(body.get("code").asString()).isEqualTo("RESOURCE_NOT_FOUND");
        assertThat(body.get("status").asInt()).isEqualTo(404);
        assertThat(body.get("title").asString()).isNotBlank();
        assertThat(body.get("detail").asString()).contains("/api/v1/does-not-exist");
        assertThat(body.get("params").get("path").asString()).isEqualTo("/api/v1/does-not-exist");
        assertThat(body.has("trace")).isFalse();
        assertThat(body.has("exception")).isFalse();
    }

    @Test
    void unsupportedMethodIsReturnedAsProblemDetails() throws Exception {
        HttpResponse<String> response = client().send("DELETE", "/api/v1/health");

        assertThat(response.statusCode()).isEqualTo(405);
        JsonNode body = HttpTestClient.json(response);
        assertThat(body.get("code").asString()).isEqualTo("METHOD_NOT_ALLOWED");
        assertThat(body.get("params").get("method").asString()).isEqualTo("DELETE");
    }

    private HttpTestClient client() {
        return new HttpTestClient(environment.getRequiredProperty("local.server.port", Integer.class));
    }
}
