package com.itsm.resolveit.testsupport;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Optional;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/** Real-HTTP client for the auth endpoints. Cookies are passed explicitly, as a browser would send them. */
public final class AuthApiClient {

    public static final String PASSWORD = "ResolveIT-Dev-2026";
    private static final JsonMapper JSON = JsonMapper.builder().build();

    private final HttpClient client = HttpClient.newHttpClient();
    private final int port;

    public AuthApiClient(int port) {
        this.port = port;
    }

    public HttpResponse<String> logIn(String email, String password) throws IOException, InterruptedException {
        java.util.Map<String, String> fields = new java.util.LinkedHashMap<>();
        if (email != null) {
            fields.put("email", email);
        }
        if (password != null) {
            fields.put("password", password);
        }
        String body = JSON.writeValueAsString(fields);
        return send(request("/api/v1/auth/login").header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body)));
    }

    public HttpResponse<String> me(String sessionCookie) throws IOException, InterruptedException {
        HttpRequest.Builder request = request("/api/v1/auth/me").GET();
        if (sessionCookie != null) {
            request.header("Cookie", sessionCookie);
        }
        return send(request);
    }

    public HttpResponse<String> send(HttpRequest.Builder request) throws IOException, InterruptedException {
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }

    public HttpRequest.Builder request(String path) {
        return HttpRequest.newBuilder(URI.create("http://localhost:" + port + path))
                .header("Accept", "application/json, application/problem+json");
    }

    /** The full Set-Cookie header for cookie {@code name}. */
    public static Optional<String> setCookie(HttpResponse<?> response, String name) {
        List<String> headers = response.headers().allValues("Set-Cookie");
        return headers.stream().filter(header -> header.startsWith(name + "=")).findFirst();
    }

    /** "NAME=value" as a browser sends it back in the Cookie header. */
    public static String cookiePair(HttpResponse<?> response, String name) {
        String header = setCookie(response, name).orElseThrow(() -> new AssertionError("no Set-Cookie for " + name));
        return header.substring(0, header.indexOf(';'));
    }

    public static JsonNode json(HttpResponse<String> response) {
        return JSON.readTree(response.body());
    }
}
