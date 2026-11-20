package com.itsm.resolveit.shared.error;

import java.util.Set;

/**
 * A stable, machine-readable error code that a domain error or a transport error carries.
 *
 * <p>Each bounded context declares its codes as an {@code enum} implementing this interface. Every
 * code must also be registered in {@link ErrorCodeRegistry} with the same required params; the
 * error-gate test fails the build otherwise.
 */
public interface ErrorCode {

    /** The code, in UPPER_SNAKE_CASE, for example {@code RESOURCE_NOT_FOUND}. */
    String code();

    /** The names of the params the user-facing message needs. */
    Set<String> requiredParams();
}
