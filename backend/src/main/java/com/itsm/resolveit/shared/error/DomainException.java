package com.itsm.resolveit.shared.error;

import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeSet;

/**
 * Base class of every business-rule refusal raised by a domain.
 *
 * <p>It carries a registered {@link ErrorCode} and the params its user-facing message needs. The
 * message is the code only: user-facing text comes from the registry, never from the exception.
 */
public abstract class DomainException extends RuntimeException {

    private final ErrorCode errorCode;
    private final Map<String, Object> params;

    protected DomainException(ErrorCode errorCode, Map<String, ?> params) {
        super(Objects.requireNonNull(errorCode, "errorCode").code());
        Objects.requireNonNull(params, "params");
        Set<String> missing = new TreeSet<>(errorCode.requiredParams());
        missing.removeAll(params.keySet());
        if (!missing.isEmpty()) {
            throw new IllegalArgumentException(
                    "Error code " + errorCode.code() + " is missing required params " + missing);
        }
        this.errorCode = errorCode;
        this.params = Map.copyOf(params);
    }

    public ErrorCode errorCode() {
        return errorCode;
    }

    public Map<String, Object> params() {
        return params;
    }
}
