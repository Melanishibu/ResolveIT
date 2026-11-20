package com.itsm.resolveit.identity.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Identity settings ({@code resolveit.session.*}).
 *
 * <p>Wiring is done inside each adapter layer, so every class keeps to the enforced onion rule
 * ({@code CleanArchitectureTest}): the persistence and integration adapters register their own port
 * implementations, and the web adapter builds the use cases it drives from port interfaces only.
 */
@Configuration(proxyBeanMethods = false)
@EnableConfigurationProperties(SessionProperties.class)
class IdentitySettingsConfig {
}
