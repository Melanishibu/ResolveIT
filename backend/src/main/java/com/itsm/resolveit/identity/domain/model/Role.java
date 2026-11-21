package com.itsm.resolveit.identity.domain.model;

/**
 * A user's role. The API and code use these names; the UI shows {@code SUPPORT_AGENT} as
 * "Technician" (Update 01, M6).
 */
public enum Role {
    ADMIN,
    SUPPORT_AGENT,
    EMPLOYEE
}
