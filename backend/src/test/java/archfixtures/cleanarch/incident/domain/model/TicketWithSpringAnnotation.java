package archfixtures.cleanarch.incident.domain.model;

import org.springframework.stereotype.Component;

/**
 * DELIBERATE VIOLATION – test fixture for ArchitectureRulesEnforcementTest.
 * A domain class must not import a Spring annotation. Lives outside com.itsm.resolveit on purpose.
 */
@Component
public class TicketWithSpringAnnotation {
}
