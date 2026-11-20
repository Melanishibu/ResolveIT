package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.model.Department;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.InvitationStatus;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.UserId;

/** The newly created user; {@code invitationStatus} is PENDING until the email has been attempted after the commit. */
public record CreatedUserView(UserId id, DisplayName name, EmailAddress email, Role role, Department department,
                              boolean active, InvitationStatus invitationStatus) {
}
