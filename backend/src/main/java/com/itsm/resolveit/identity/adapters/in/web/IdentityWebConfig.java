package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.application.port.in.ChangePasswordUseCase;
import com.itsm.resolveit.identity.application.port.in.CreateUserUseCase;
import com.itsm.resolveit.identity.application.port.in.GetCurrentUserUseCase;
import com.itsm.resolveit.identity.application.port.in.GetMyProfileUseCase;
import com.itsm.resolveit.identity.application.service.ChangePasswordService;
import com.itsm.resolveit.identity.application.service.GetMyProfileService;
import com.itsm.resolveit.identity.application.port.out.DomainEventPublisher;
import com.itsm.resolveit.identity.application.port.out.FailedLoginCounterRepository;
import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.service.CreateUserService;
import com.itsm.resolveit.identity.application.service.SetPasswordService;
import com.itsm.resolveit.identity.application.service.UserAdministrationService;
import com.itsm.resolveit.identity.application.port.out.UserListReadModel;
import com.itsm.resolveit.identity.application.port.in.SetPasswordUseCase;
import com.itsm.resolveit.identity.application.port.out.PasswordHasher;
import com.itsm.resolveit.identity.application.port.in.LogInUseCase;
import com.itsm.resolveit.identity.application.port.in.LogOutUseCase;
import com.itsm.resolveit.identity.application.port.out.PasswordVerifier;
import com.itsm.resolveit.identity.application.port.out.SessionTokenIssuer;
import com.itsm.resolveit.identity.application.port.out.SessionTokenVerifier;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.application.port.out.UserSessionRepository;
import com.itsm.resolveit.identity.application.service.GetCurrentUserService;
import com.itsm.resolveit.identity.application.service.LogInService;
import com.itsm.resolveit.identity.application.service.LogOutService;
import com.itsm.resolveit.identity.config.SessionProperties;
import com.itsm.resolveit.identity.domain.model.LoginLockoutPolicy;
import io.swagger.v3.oas.models.security.SecurityScheme;
import java.time.Clock;
import java.util.List;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Builds the use cases this web adapter drives, from port interfaces only (the implementations are
 * registered by the persistence and integration adapters), plus the session cookies and the OpenAPI
 * security scheme.
 */
// ARCH-DEVIATION: wiring inside the adapter layer instead of identity/config, because the enforced onion rule
// (ArchitectureRules.ONION) has no config layer; open question A on AB#13 (Melani Shibu). Rule: clean-architecture §1.
@Configuration(proxyBeanMethods = false)
class IdentityWebConfig {

    @Bean
    LogInUseCase logInUseCase(UserRepository users, FailedLoginCounterRepository failedLogins,
                              UserSessionRepository sessions, PasswordVerifier passwords, SessionTokenIssuer tokens,
                              SessionProperties properties, ObjectProvider<Clock> clock) {
        return new LogInService(users, failedLogins, sessions, passwords, tokens, LoginLockoutPolicy.STANDARD,
                properties.lifetime(), clock(clock));
    }

    @Bean
    LogOutUseCase logOutUseCase(UserSessionRepository sessions, SessionTokenVerifier tokens) {
        return new LogOutService(sessions, tokens);
    }

    @Bean
    GetCurrentUserUseCase getCurrentUserUseCase(SessionTokenVerifier tokens, UserSessionRepository sessions,
                                                UserRepository users, ObjectProvider<Clock> clock) {
        return new GetCurrentUserService(tokens, sessions, users, clock(clock));
    }

    @Bean
    CreateUserUseCase createUserUseCase(UserRepository users, InvitationRepository invitations, UserAuditLog auditLog,
                                        DomainEventPublisher events, ObjectProvider<Clock> clock) {
        return new CreateUserService(users, invitations, auditLog, events, clock(clock));
    }

    @Bean
    com.itsm.resolveit.identity.application.port.in.ResendInvitationUseCase resendInvitationUseCase(
            UserRepository users, InvitationRepository invitations,
            com.itsm.resolveit.identity.application.port.out.UserListReadModel readModel,
            UserAuditLog auditLog, DomainEventPublisher events, ObjectProvider<Clock> clock) {
        return new com.itsm.resolveit.identity.application.service.ResendInvitationService(
                users, invitations, readModel, auditLog, events, clock(clock));
    }

    @Bean
    UserAdministrationService userAdministration(UserRepository users, UserListReadModel readModel,
                                                 UserAuditLog auditLog, ObjectProvider<Clock> clock) {
        return new UserAdministrationService(users, readModel, auditLog, clock(clock));
    }

    @Bean
    SetPasswordUseCase setPasswordUseCase(InvitationRepository invitations, UserRepository users,
                                          PasswordHasher hasher, UserAuditLog auditLog, ObjectProvider<Clock> clock) {
        return new SetPasswordService(invitations, users, hasher, auditLog, clock(clock));
    }

    @Bean
    GetMyProfileUseCase getMyProfileUseCase(UserRepository users) {
        return new GetMyProfileService(users);
    }

    @Bean
    ChangePasswordUseCase changePasswordUseCase(UserRepository users, UserSessionRepository sessions,
                                                PasswordVerifier verifier, PasswordHasher hasher,
                                                UserAuditLog auditLog, ObjectProvider<Clock> clock) {
        return new ChangePasswordService(users, sessions, verifier, hasher, auditLog, clock(clock));
    }

    /** Request protection (RIT-US-05): CSRF and session check on every ResolveIT endpoint, plus the Actor parameter. */
    @Bean
    WebMvcConfigurer requestProtection(GetCurrentUserUseCase currentUser) {
        return new WebMvcConfigurer() {
            @Override
            public void addInterceptors(InterceptorRegistry registry) {
                registry.addInterceptor(new RequestProtectionInterceptor(currentUser));
            }

            @Override
            public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
                resolvers.add(new CurrentUserArgumentResolver());
            }
        };
    }

    @Bean
    SessionCookies sessionCookies(SessionProperties properties) {
        return new SessionCookies(properties.lifetime());
    }

    /** Documents the session cookie as the API's security scheme (used by {@code GET /auth/me}). */
    @Bean
    OpenApiCustomizer sessionCookieSecurityScheme() {
        return openApi -> openApi.getComponents().addSecuritySchemes(SessionCookies.SESSION_COOKIE,
                new SecurityScheme()
                        .type(SecurityScheme.Type.APIKEY)
                        .in(SecurityScheme.In.COOKIE)
                        .name(SessionCookies.SESSION_COOKIE)
                        .description("Session cookie set by POST /api/v1/auth/login (HttpOnly, Secure, SameSite=Strict)"));
    }

    /** A test may provide its own {@link Clock} bean; otherwise the system clock in UTC. */
    private static Clock clock(ObjectProvider<Clock> clock) {
        return clock.getIfAvailable(Clock::systemUTC);
    }
}
