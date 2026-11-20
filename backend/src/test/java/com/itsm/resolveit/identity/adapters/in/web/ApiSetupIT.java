package com.itsm.resolveit.identity.adapters.in.web;

import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.TestcontainersConfiguration;
import com.itsm.resolveit.testsupport.AuthApiClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;
import tools.jackson.databind.JsonNode;

/** RIT-US-04 setup checks with the plain test profile (no dev seed). */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration.class)
class ApiSetupIT {

    @Autowired
    private Environment environment;

    @Autowired
    private JdbcClient jdbc;

    @Test
    void devSeedUsersAreLoadedOnlyWithTheDevProfile() {
        Integer users = jdbc.sql("SELECT count(*) FROM identity.app_user").query(Integer.class).single();

        assertThat(users).as("the test profile must not contain the dev seed users").isZero();
    }

    @Test
    void openApiDocumentsTheAuthEndpointsUnderTheResolveItApiTitle() throws Exception {
        HttpResponse<String> response = api().send(api().request("/api/docs").GET());

        JsonNode openApi = AuthApiClient.json(response);
        assertThat(openApi.get("info").get("title").asString()).isEqualTo("ResolveIT API");
        JsonNode paths = openApi.get("paths");
        assertThat(paths.has("/api/v1/auth/login")).isTrue();
        assertThat(paths.has("/api/v1/auth/logout")).isTrue();
        assertThat(paths.has("/api/v1/auth/me")).isTrue();
        assertThat(openApi.get("components").get("securitySchemes").has("RIT_SESSION")).isTrue();
    }

    @Test
    void theConfiguredFrontendOriginMayCallTheApiWithCookies() throws Exception {
        HttpResponse<String> preflight = api().send(api().request("/api/v1/auth/login")
                .header("Origin", "http://localhost:5000")
                .header("Access-Control-Request-Method", "POST")
                .header("Access-Control-Request-Headers", "content-type,x-xsrf-token")
                .method("OPTIONS", HttpRequest.BodyPublishers.noBody()));

        assertThat(preflight.statusCode()).isEqualTo(200);
        assertThat(preflight.headers().firstValue("Access-Control-Allow-Origin")).contains("http://localhost:5000");
        assertThat(preflight.headers().firstValue("Access-Control-Allow-Credentials")).contains("true");
    }

    private AuthApiClient api() {
        return new AuthApiClient(environment.getRequiredProperty("local.server.port", Integer.class));
    }
}
