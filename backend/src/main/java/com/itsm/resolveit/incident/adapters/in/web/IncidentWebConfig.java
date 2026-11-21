package com.itsm.resolveit.incident.adapters.in.web;

import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsUseCase;
import com.itsm.resolveit.incident.application.port.in.ReportIncidentUseCase;
import com.itsm.resolveit.incident.application.port.out.UserDirectory;
import com.itsm.resolveit.incident.application.service.GetIncidentDetailsService;
import com.itsm.resolveit.incident.application.port.out.IncidentAuditLog;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.application.port.out.TicketNumberGenerator;
import com.itsm.resolveit.incident.application.service.ReportIncidentService;
import java.time.Clock;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Builds the incident use cases this web adapter drives, from port interfaces only. */
// ARCH-DEVIATION: wiring inside the adapter layer instead of incident/config, because the enforced onion rule
// (ArchitectureRules.ONION) has no config layer; open question A on AB#13 (Melani Shibu). Rule: clean-architecture §1.
@Configuration(proxyBeanMethods = false)
class IncidentWebConfig {

    @Bean
    GetIncidentDetailsUseCase getIncidentDetailsUseCase(IncidentRepository incidents, UserDirectory users) {
        return new GetIncidentDetailsService(incidents, users);
    }

    @Bean
    com.itsm.resolveit.incident.application.port.in.ListIncidentsUseCase listIncidentsUseCase(
            com.itsm.resolveit.incident.application.port.out.IncidentListReadModel readModel, UserDirectory users) {
        return new com.itsm.resolveit.incident.application.service.ListIncidentsService(readModel, users);
    }

    @Bean
    ReportIncidentUseCase reportIncidentUseCase(IncidentRepository incidents, TicketNumberGenerator ticketNumbers,
                                                IncidentAuditLog auditLog, ObjectProvider<Clock> clock) {
        return new ReportIncidentService(incidents, ticketNumbers, auditLog, clock.getIfAvailable(Clock::systemUTC));
    }
}
