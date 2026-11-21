package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.event.UserInvited;

/**
 * Use case: send the invitation email after the user was created (RIT-US-06). Records SENT and the
 * INVITATION_SENT audit entry, or SEND_FAILED when the mail server refuses or is unreachable.
 */
public interface SendInvitationUseCase {

    void send(UserInvited event);
}
