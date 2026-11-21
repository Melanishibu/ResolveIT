package com.itsm.resolveit.incident.adapters.out.persistence;

import com.itsm.resolveit.incident.application.port.out.IncidentAuditLog;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.application.port.out.TicketNumberGenerator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.simple.JdbcClient;

// ARCH-DEVIATION: wiring inside the adapter layer instead of incident/config, because the enforced onion rule
// (ArchitectureRules.ONION) has no config layer; open question A on AB#13 (Melani Shibu). Rule: clean-architecture §1.
/** Registers the JDBC implementations of the incident ports. */
@Configuration(proxyBeanMethods = false)
class IncidentPersistenceConfig {

    @Bean
    IncidentRepository incidentRepository(JdbcClient jdbc) {
        return new JdbcIncidentRepository(jdbc);
    }

    @Bean
    TicketNumberGenerator ticketNumberGenerator(JdbcClient jdbc) {
        return new JdbcTicketNumberGenerator(jdbc);
    }

    @Bean
    IncidentAuditLog incidentAuditLog(JdbcClient jdbc) {
        return new JdbcIncidentAuditLog(jdbc);
    }
}
