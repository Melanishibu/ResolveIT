package com.itsm.resolveit.identity.adapters.out.integration;

import com.itsm.resolveit.identity.application.port.out.EmailSender;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;

/**
 * {@link EmailSender} over SMTP (Mailpit locally). Host and port come from {@code RESOLVEIT_SMTP_HOST} /
 * {@code RESOLVEIT_SMTP_PORT}, the sender from {@code RESOLVEIT_MAIL_FROM}.
 */
public class SmtpEmailSender implements EmailSender {

    private final JavaMailSender mailSender;
    private final String from;

    public SmtpEmailSender(JavaMailSender mailSender, String from) {
        this.mailSender = mailSender;
        this.from = from;
    }

    @Override
    public void send(EmailMessage message) {
        SimpleMailMessage mail = new SimpleMailMessage();
        mail.setFrom(from);
        mail.setTo(message.to().value());
        mail.setSubject(message.subject());
        mail.setText(message.body());
        try {
            mailSender.send(mail);
        } catch (MailException failed) {
            // The exception text names the mail server problem, never the message body (which holds a link).
            throw new EmailNotSentException("Mail server refused or unreachable: " + failed.getClass().getSimpleName(),
                    failed);
        }
    }
}
