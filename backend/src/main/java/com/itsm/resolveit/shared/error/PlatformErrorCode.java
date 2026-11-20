package com.itsm.resolveit.shared.error;

import java.util.Set;

/** Error codes raised by the platform itself (transport and unexpected failures), not by a bounded context. */
public enum PlatformErrorCode implements ErrorCode {

    RESOURCE_NOT_FOUND(Set.of("path")),
    METHOD_NOT_ALLOWED(Set.of("method", "path")),
    VALIDATION_FAILED(Set.of("fields")),
    REQUEST_NOT_SUPPORTED(Set.of("path")),
    INTERNAL_ERROR(Set.of("traceId"));

    private final Set<String> requiredParams;

    PlatformErrorCode(Set<String> requiredParams) {
        this.requiredParams = requiredParams;
    }

    @Override
    public String code() {
        return name();
    }

    @Override
    public Set<String> requiredParams() {
        return requiredParams;
    }
}
