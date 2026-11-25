package com.itsm.resolveit.identity;

import com.itsm.resolveit.shared.error.DomainException;
import com.itsm.resolveit.shared.error.ErrorCode;
import java.util.Map;
import java.util.Set;

/** The user is logged in, but their role doesn't allow the operation ({@code AUTH_FORBIDDEN}, 403). */
public final class AccessDeniedException extends DomainException {

    public AccessDeniedException() {
        super(AccessErrorCode.AUTH_FORBIDDEN, Map.of());
    }

    /** Error codes of the published access API (registered in {@code ErrorCodeRegistry}). */
    public enum AccessErrorCode implements ErrorCode {
        AUTH_FORBIDDEN;

        @Override
        public String code() {
            return name();
        }

        @Override
        public Set<String> requiredParams() {
            return Set.of();
        }
    }
}
