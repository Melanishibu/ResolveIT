package com.itsm.resolveit.identity.domain.model;

/** Where an invitation stands (RIT-US-06; USED arrives with RIT-US-07). */
public enum InvitationStatus {
    /** Created; the email has not been attempted yet. */
    PENDING,
    /** The invitation email was handed to the mail server. */
    SENT,
    /** Sending failed; the user exists and can be invited again (RIT-US-22). */
    SEND_FAILED,
    /** The password was set with this invitation (single use). */
    USED
}
