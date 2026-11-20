package com.itsm.resolveit.identity.adapters.out.integration;

import com.itsm.resolveit.identity.application.port.out.PasswordVerifier;
import com.itsm.resolveit.identity.config.SessionProperties;
import com.itsm.resolveit.identity.config.SessionSigningKeys;
import java.time.Clock;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * Registers the BCrypt password verifier and the JWT session tokens. The token bean serves both the
 * {@code SessionTokenIssuer} and the {@code SessionTokenVerifier} port.
 */
// ARCH-DEVIATION: wiring inside the adapter layer instead of identity/config, because the enforced onion rule
// (ArchitectureRules.ONION) has no config layer; open question A on AB#13 (Melani Shibu). Rule: clean-architecture §1.
@Configuration(proxyBeanMethods = false)
class IdentitySecurityConfig {

    @Bean
    PasswordVerifier passwordVerifier() {
        return new BCryptPasswordVerifier(new BCryptPasswordEncoder());
    }

    @Bean
    JwtSessionTokens sessionTokens(SessionProperties properties, ObjectProvider<Clock> clock) {
        return new JwtSessionTokens(SessionSigningKeys.resolve(properties), clock.getIfAvailable(Clock::systemUTC));
    }
}
