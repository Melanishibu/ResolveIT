package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.UserRow;

/** Resend an invitation email (RIT-US-22). */
public interface ResendInvitationUseCase {
    UserRow resend(ResendInvitationCommand command);
}
