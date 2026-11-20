package com.itsm.resolveit.shared.error;

import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * The single error-code registry of the ResolveIT backend.
 *
 * <p>This is the reviewed contract between backend and frontend: it is published as
 * {@code contracts/error-codes.json} (kept in step by {@code ErrorCodeContractTest}) and the
 * frontend catalogue gate checks its entries against that file. Add a code here in the same change
 * that introduces it. Texts are English (deviation D3).
 */
public final class ErrorCodeRegistry {

    private static final Map<String, RegisteredErrorCode> ENTRIES = new LinkedHashMap<>();

    static {
        register(new RegisteredErrorCode(
                "RESOURCE_NOT_FOUND", 404, Set.of("path"),
                "This page or item doesn't exist",
                "Nothing is available at {path}. The link may be outdated or mistyped.",
                "Check the address, or go back to the dashboard and open the item from there."));
        register(new RegisteredErrorCode(
                "METHOD_NOT_ALLOWED", 405, Set.of("method", "path"),
                "This action isn't available here",
                "{path} does not accept {method} requests.",
                "Reload the page and try again. If it keeps happening, report it to the ResolveIT administrator."));
        register(new RegisteredErrorCode(
                "VALIDATION_FAILED", 400, Set.of("fields"),
                "Some information is missing or invalid",
                "The request could not be accepted because these fields are missing or invalid: {fields}.",
                "Correct the highlighted fields and submit again."));
        register(new RegisteredErrorCode(
                "REQUEST_NOT_SUPPORTED", 400, Set.of("path"),
                "This request can't be processed",
                "The request to {path} uses a format or option that ResolveIT doesn't support.",
                "Reload the page and try again. If it keeps happening, report it to the ResolveIT administrator."));
        register(new RegisteredErrorCode(
                "INTERNAL_ERROR", 500, Set.of("traceId"),
                "Something went wrong on our side",
                "ResolveIT couldn't complete the request because of an unexpected error.",
                "Try again in a moment. If it keeps happening, contact the ResolveIT administrator and quote the reference shown under Details."));

        // Identity (AB#13). The credentials message never says whether the email or the password was wrong.
        register(new RegisteredErrorCode(
                "AUTH_INVALID_CREDENTIALS", 401, Set.of(),
                "Email or password is incorrect",
                "The email address and password you entered don't match an active ResolveIT account.",
                "Check both and try again. After 5 failed attempts in a row, login is blocked for 15 minutes."
                        + " If you forgot your password, contact your ResolveIT administrator."));
        register(new RegisteredErrorCode(
                "AUTH_LOGIN_TEMPORARILY_BLOCKED", 429, Set.of("retryAfterMinutes"),
                "Login is temporarily blocked",
                "There were 5 failed login attempts in a row for this account, so login is blocked for security"
                        + " for about {retryAfterMinutes} more minute(s).",
                "Wait until the block ends, then log in with the correct password."
                        + " If you don't remember it, contact your ResolveIT administrator."));
        register(new RegisteredErrorCode(
                "AUTH_UNAUTHENTICATED", 401, Set.of(),
                "You're not logged in",
                "Your session has ended or is no longer valid, for example after you logged out, after 8 hours,"
                        + " or because your account was deactivated.",
                "Log in again with your email address and password."));
        // Request protection (AB#14).
        register(new RegisteredErrorCode(
                "AUTH_FORBIDDEN", 403, Set.of(),
                "You don't have access to this",
                "Your role doesn't allow this action or page in ResolveIT.",
                "If you need it for your work, ask your ResolveIT administrator. Otherwise go back to the dashboard."));
        register(new RegisteredErrorCode(
                "AUTH_CSRF_INVALID", 403, Set.of(),
                "This request couldn't be verified",
                "The security token that protects your session was missing or didn't match, so ResolveIT refused"
                        + " the change.",
                "Reload the page and try again. If it keeps happening, log out and log in again."));
        // User management (AB#48).
        register(new RegisteredErrorCode(
                "USER_EMAIL_TAKEN", 409, Set.of("email"),
                "This email address is already in use",
                "A ResolveIT user with the email address {email} already exists. Email addresses are unique,"
                        + " regardless of upper or lower case.",
                "Use a different email address, or find the existing user in User Management."));
        register(new RegisteredErrorCode(
                "USER_ROLE_NOT_ALLOWED", 400, Set.of("role"),
                "This role can't be given to a new user",
                "New users can only be Technicians or Employees; the role {role} can't be created here.",
                "Choose Technician or Employee and create the user again."));
    }

    private ErrorCodeRegistry() {
    }

    /** Looks up a registered code. */
    public static Optional<RegisteredErrorCode> find(String code) {
        return Optional.ofNullable(ENTRIES.get(code));
    }

    /** Returns the registry entry for a code that must be registered (the error gate guarantees it). */
    public static RegisteredErrorCode entryFor(ErrorCode errorCode) {
        return find(errorCode.code()).orElseThrow(() -> new IllegalStateException(
                "Error code " + errorCode.code() + " is not registered in ErrorCodeRegistry"));
    }

    /** All registered codes, sorted by code. */
    public static List<RegisteredErrorCode> all() {
        return ENTRIES.values().stream().sorted(Comparator.comparing(RegisteredErrorCode::code)).toList();
    }

    private static void register(RegisteredErrorCode entry) {
        if (ENTRIES.putIfAbsent(entry.code(), entry) != null) {
            throw new IllegalStateException("Error code registered twice: " + entry.code());
        }
    }
}
