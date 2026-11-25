package com.itsm.resolveit.identity.adapters.out.persistence;

import com.itsm.resolveit.identity.application.port.out.FailedLoginCounterRepository;
import com.itsm.resolveit.identity.UserLookup;
import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.application.port.out.UserSessionRepository;
import com.itsm.resolveit.identity.application.port.out.UserListReadModel;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.simple.JdbcClient;

/** Registers the JDBC implementations of the identity repositories. */
// ARCH-DEVIATION: wiring inside the adapter layer instead of identity/config, because the enforced onion rule
// (ArchitectureRules.ONION) has no config layer; open question A on AB#13 (Melani Shibu). Rule: clean-architecture §1.
@Configuration(proxyBeanMethods = false)
class IdentityPersistenceConfig {

    @Bean
    UserListReadModel userListReadModel(JdbcClient jdbc) {
        return new JdbcUserListQuery(jdbc);
    }

    @Bean
    UserLookup userLookup(JdbcClient jdbc) {
        return new JdbcUserLookup(jdbc);
    }

    @Bean
    UserRepository userRepository(JdbcClient jdbc) {
        return new JdbcUserRepository(jdbc);
    }

    @Bean
    FailedLoginCounterRepository failedLoginCounterRepository(JdbcClient jdbc) {
        return new JdbcFailedLoginCounterRepository(jdbc);
    }

    @Bean
    UserSessionRepository userSessionRepository(JdbcClient jdbc) {
        return new JdbcUserSessionRepository(jdbc);
    }

    @Bean
    InvitationRepository invitationRepository(JdbcClient jdbc) {
        return new JdbcInvitationRepository(jdbc);
    }

    @Bean
    UserAuditLog userAuditLog(JdbcClient jdbc) {
        return new JdbcUserAuditLog(jdbc);
    }
}
