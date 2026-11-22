package com.itsm.resolveit.identity.adapters.in.messaging;

import com.itsm.resolveit.identity.application.port.in.SendInvitationUseCase;
import com.itsm.resolveit.identity.application.port.in.SendPasswordResetUseCase;
import com.itsm.resolveit.identity.application.port.out.EmailSender;
import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.service.InvitationEmail;
import com.itsm.resolveit.identity.application.service.PasswordResetEmail;
import com.itsm.resolveit.identity.application.service.SendInvitationService;
import com.itsm.resolveit.identity.application.service.SendPasswordResetService;
import java.time.Clock;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// ARCH-DEVIATION: wiring inside the adapter layer instead of identity/config, because the enforced onion rule
// (ArchitectureRules.ONION) has no config layer; open question A on AB#13 (Melani Shibu). Rule: clean-architecture §1.
/** Builds the after-commit invitation sending: the use case this listener drives, from port interfaces only. */
@Configuration(proxyBeanMethods = false)
class IdentityMessagingConfig {

    @Bean
    SendInvitationUseCase sendInvitationUseCase(InvitationRepository invitations, UserAuditLog auditLog,
                                                EmailSender emailSender,
                                                @Value("${resolveit.frontend-base-url}") String frontendBaseUrl,
                                                ObjectProvider<Clock> clock) {
        return new SendInvitationService(invitations, auditLog, emailSender, new InvitationEmail(frontendBaseUrl),
                clock.getIfAvailable(Clock::systemUTC));
    }

    @Bean
    UserInvitedListener userInvitedListener(SendInvitationUseCase sendInvitation) {
        return new UserInvitedListener(sendInvitation);
    }

    @Bean
    SendPasswordResetUseCase sendPasswordResetUseCase(InvitationRepository invitations,
                                                     EmailSender emailSender,
                                                     @Value("${resolveit.frontend-base-url}") String frontendBaseUrl) {
        return new SendPasswordResetService(invitations, emailSender, new PasswordResetEmail(frontendBaseUrl));
    }

    @Bean
    PasswordResetRequestedListener passwordResetRequestedListener(SendPasswordResetUseCase sendPasswordReset) {
        return new PasswordResetRequestedListener(sendPasswordReset);
    }
}
