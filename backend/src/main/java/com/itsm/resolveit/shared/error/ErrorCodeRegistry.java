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
