package com.itsm.resolveit.shared.error;

import java.util.Objects;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Pattern;

/**
 * One entry of the {@link ErrorCodeRegistry}: everything a client needs to show the error to a user.
 *
 * @param code           stable UPPER_SNAKE_CASE code
 * @param httpStatus     HTTP status the API answers with
 * @param requiredParams params the message needs; {@code {name}} placeholders in {@code why} and
 *                       {@code nextStep} may only use these
 * @param title          what happened
 * @param why            the rule or cause, naming the concrete things involved
 * @param nextStep       what the user should do next
 */
public record RegisteredErrorCode(
        String code, int httpStatus, Set<String> requiredParams, String title, String why, String nextStep) {

    private static final Pattern CODE_FORMAT = Pattern.compile("[A-Z][A-Z0-9]*(_[A-Z0-9]+)*");

    public RegisteredErrorCode {
        Objects.requireNonNull(code, "code");
        if (!CODE_FORMAT.matcher(code).matches()) {
            throw new IllegalArgumentException("Error code must be UPPER_SNAKE_CASE: " + code);
        }
        if (httpStatus < 400 || httpStatus > 599) {
            throw new IllegalArgumentException("Error code " + code + " needs a 4xx or 5xx status, not " + httpStatus);
        }
        requiredParams = Set.copyOf(Objects.requireNonNull(requiredParams, "requiredParams"));
        requireText(code, "title", title);
        requireText(code, "why", why);
        requireText(code, "nextStep", nextStep);
    }

    /** The required params in alphabetical order, for stable output. */
    public Set<String> sortedRequiredParams() {
        return new TreeSet<>(requiredParams);
    }

    private static void requireText(String code, String field, String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Error code " + code + " needs a non-blank " + field);
        }
    }
}
