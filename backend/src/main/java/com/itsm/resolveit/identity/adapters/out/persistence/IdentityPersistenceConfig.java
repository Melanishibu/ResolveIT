package com.itsm.resolveit.identity.adapters.out.persistence;

import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.application.port.out.UserSessionRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.simple.JdbcClient;

/** Registers the JDBC implementations of the identity repositories. */
// ARCH-DEVIATION: wiring inside the adapter layer instead of identity/config, because the enforced onion rule
// (ArchitectureRules.ONION) has no config layer; open question A on AB#13 (Melani Shibu). Rule: clean-architecture §1.
@Configuration(proxyBeanMethods = false)
class IdentityPersistenceConfig {

    @Bean
    UserRepository userRepository(JdbcClient jdbc) {
        return new JdbcUserRepository(jdbc);
    }

    @Bean
    UserSessionRepository userSessionRepository(JdbcClient jdbc) {
        return new JdbcUserSessionRepository(jdbc);
    }
}
