package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.CsrfExempt;
import com.itsm.resolveit.identity.PublicEndpoint;
import com.itsm.resolveit.identity.application.port.in.CurrentUserView;
import com.itsm.resolveit.identity.application.port.in.LogInCommand;
import com.itsm.resolveit.identity.application.port.in.LogInUseCase;
import com.itsm.resolveit.identity.application.port.in.LogOutUseCase;
import com.itsm.resolveit.identity.application.port.in.LoginResult;
import com.itsm.resolveit.identity.domain.model.SessionToken;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.Optional;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Login, logout and "who am I" (RIT-US-04). Paths are relative to the API base {@code /api/v1}. */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "Log in, log out and read the current user")
class AuthController {

    private final LogInUseCase logIn;
    private final LogOutUseCase logOut;
    private final SessionCookies cookies;

    AuthController(LogInUseCase logIn, LogOutUseCase logOut, SessionCookies cookies) {
        this.logIn = logIn;
        this.logOut = logOut;
        this.cookies = cookies;
    }

    @PostMapping("/login")
    @PublicEndpoint
    @CsrfExempt
    @Operation(summary = "Log in with email and password",
            description = "Sets the RIT_SESSION cookie (session, 8 h, HttpOnly, Secure, SameSite=Strict) and the"
                    + " XSRF-TOKEN cookie. 5 failed attempts in a row lock the account for 15 minutes.")
    @ApiResponse(responseCode = "200", description = "Logged in; cookies set")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "401", description = "AUTH_INVALID_CREDENTIALS",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "429", description = "AUTH_LOGIN_TEMPORARILY_BLOCKED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    ResponseEntity<CurrentUserResponse> logIn(@Valid @RequestBody LoginRequest request) {
        LoginResult result = logIn.logIn(new LogInCommand(request.email(), request.password()));
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, cookies.session(result.token()).toString())
                .header(HttpHeaders.SET_COOKIE, cookies.newXsrfToken().toString())
                .body(CurrentUserResponse.of(result.user()));
    }

    @PostMapping("/logout")
    @PublicEndpoint
    @Operation(summary = "Log out", description = "Ends the session and clears both cookies. 204 whenever the CSRF token is valid (also without a session).")
    @ApiResponse(responseCode = "204", description = "Logged out")
    @ApiResponse(responseCode = "403", description = "AUTH_CSRF_INVALID (X-XSRF-TOKEN header missing or not matching)",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    ResponseEntity<Void> logOut(
            @CookieValue(name = SessionCookies.SESSION_COOKIE, required = false) String sessionToken) {
        logOut.logOut(token(sessionToken));
        return ResponseEntity.noContent()
                .header(HttpHeaders.SET_COOKIE, cookies.clearedSession().toString())
                .header(HttpHeaders.SET_COOKIE, cookies.clearedXsrfToken().toString())
                .build();
    }

    @GetMapping("/me")
    @Operation(summary = "The logged-in user", security = @SecurityRequirement(name = SessionCookies.SESSION_COOKIE))
    @ApiResponse(responseCode = "200", description = "The current user")
    @ApiResponse(responseCode = "401", description = "AUTH_UNAUTHENTICATED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    CurrentUserResponse me(CurrentUserView user) {
        // The session was checked by RequestProtectionInterceptor (401 AUTH_UNAUTHENTICATED without one).
        return CurrentUserResponse.of(user);
    }

    private static Optional<SessionToken> token(String cookieValue) {
        return cookieValue == null || cookieValue.isBlank() ? Optional.empty() : Optional.of(new SessionToken(cookieValue));
    }
}
