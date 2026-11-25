package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.EmailAddress;
import java.util.Objects;

/** Outbound port: sends a transactional email (RIT-US-06; SMTP adapter, Mailpit locally). */
public interface EmailSender {

    /** Sends {@code message}; throws {@link EmailNotSentException} if the mail server refuses it or can't be reached. */
    void send(EmailMessage message);

    /** A plain-text email. Never contains a password. */
    record EmailMessage(EmailAddress to, String subject, String body) {

        public EmailMessage {
            Objects.requireNonNull(to, "to");
            Objects.requireNonNull(subject, "subject");
            Objects.requireNonNull(body, "body");
        }

        /** The body holds a one-time link: never print it. */
        @Override
        public String toString() {
            return "EmailMessage[to=" + to + ", subject=" + subject + ", body=***]";
        }
    }

    /** The email could not be handed to the mail server. */
    final class EmailNotSentException extends RuntimeException {

        public EmailNotSentException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
