package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.model.Department;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.time.Instant;

/** The profile data of the logged-in user (RIT-US-27). */
public record UserProfileView(
        UserId id,
        DisplayName name,
        EmailAddress email,
        Role role,
        Department department,
        Instant memberSince) {
}
