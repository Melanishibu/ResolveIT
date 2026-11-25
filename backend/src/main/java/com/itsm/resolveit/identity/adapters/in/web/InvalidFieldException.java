package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.shared.error.DomainException;
import com.itsm.resolveit.shared.error.PlatformErrorCode;
import java.util.List;
import java.util.Map;

/** A request field passed the transport checks but not the domain's value rules ({@code VALIDATION_FAILED}, 400). */
final class InvalidFieldException extends DomainException {

    InvalidFieldException(String field) {
        super(PlatformErrorCode.VALIDATION_FAILED, Map.of("fields", List.of(field)));
    }
}
