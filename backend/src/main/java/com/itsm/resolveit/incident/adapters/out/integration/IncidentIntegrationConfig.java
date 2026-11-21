package com.itsm.resolveit.incident.adapters.out.integration;

import com.itsm.resolveit.identity.UserLookup;
import com.itsm.resolveit.incident.application.port.out.UserDirectory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// ARCH-DEVIATION: wiring inside the adapter layer instead of incident/config, because the enforced onion rule
// (ArchitectureRules.ONION) has no config layer; open question A on AB#13 (Melani Shibu). Rule: clean-architecture §1.
/** Registers the incident context's adapters to other contexts. */
@Configuration(proxyBeanMethods = false)
class IncidentIntegrationConfig {

    @Bean
    UserDirectory userDirectory(UserLookup userLookup) {
        return new IdentityUserDirectory(userLookup);
    }
}
