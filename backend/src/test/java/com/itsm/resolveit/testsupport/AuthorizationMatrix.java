package com.itsm.resolveit.testsupport;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Reusable authorisation test harness (RIT-US-05): logs in one dev-seed user per role and checks
 * the expected HTTP status of an endpoint for each role, plus for an anonymous caller.
 *
 * <p>Use it in an integration test that loads the dev seed
 * ({@code spring.flyway.locations=classpath:db/migration,classpath:db/dev-seed}):
 * <pre>{@code
 * new AuthorizationMatrix(port).endpoint("GET", "/api/v1/users")
 *         .expect(Role.ADMIN, 200).expect(Role.SUPPORT_AGENT, 403).expect(Role.EMPLOYEE, 403)
 *         .expectAnonymous(401).verify();
 * }</pre>
 * State-changing requests are sent with the CSRF token, so the check is about the role only.
 */
public final class AuthorizationMatrix {

    /** One dev-seed user per role. */
    public enum Role {
        ADMIN("admin@resolveit.local"),
        SUPPORT_AGENT("agent1@resolveit.local"),
        EMPLOYEE("employee1@resolveit.local");

        final String email;

        Role(String email) {
            this.email = email;
        }
    }

    /** The cookies and CSRF token of a logged-in user. */
    public record Session(String cookieHeader, String xsrfToken) {
    }

    private final AuthApiClient api;
    private String method = "GET";
    private String path;
    private final Map<Role, Integer> expected = new LinkedHashMap<>();
    private Integer anonymous;

    public AuthorizationMatrix(int port) {
        this.api = new AuthApiClient(port);
    }

    public AuthorizationMatrix endpoint(String httpMethod, String endpointPath) {
        this.method = httpMethod;
        this.path = endpointPath;
        return this;
    }

    public AuthorizationMatrix expect(Role role, int status) {
        expected.put(role, status);
        return this;
    }

    public AuthorizationMatrix expectAnonymous(int status) {
        anonymous = status;
        return this;
    }

    /** Sends the request once per role (and anonymously) and asserts every status. */
    public void verify() throws IOException, InterruptedException {
        for (Map.Entry<Role, Integer> entry : expected.entrySet()) {
            assertThat(send(logIn(entry.getKey())).statusCode())
                    .as("%s %s as %s", method, path, entry.getKey())
                    .isEqualTo(entry.getValue());
        }
        if (anonymous != null) {
            assertThat(send(null).statusCode()).as("%s %s without a session", method, path).isEqualTo(anonymous);
        }
    }

    public Session logIn(Role role) throws IOException, InterruptedException {
        HttpResponse<String> login = api.logIn(role.email, AuthApiClient.PASSWORD);
        assertThat(login.statusCode()).as("login as %s", role).isEqualTo(200);
        String session = AuthApiClient.cookiePair(login, "RIT_SESSION");
        String xsrf = AuthApiClient.cookiePair(login, "XSRF-TOKEN");
        return new Session(session + "; " + xsrf, xsrf.substring(xsrf.indexOf('=') + 1));
    }

    public HttpResponse<String> send(Session session) throws IOException, InterruptedException {
        HttpRequest.Builder request = api.request(path).method(method, HttpRequest.BodyPublishers.noBody());
        if (session != null) {
            request.header("Cookie", session.cookieHeader()).header("X-XSRF-TOKEN", session.xsrfToken());
        }
        return api.send(request);
    }
}
