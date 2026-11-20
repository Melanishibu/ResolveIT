package com.itsm.resolveit;

import static org.assertj.core.api.Assertions.assertThat;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.lang.EvaluationResult;
import org.junit.jupiter.api.Test;

/**
 * Scenario: Architecture rules are enforced.
 *
 * <p>Proves the rules in {@link CleanArchitectureTest} really fail: the fixture package
 * {@code archfixtures.cleanarch} (test code, outside {@code com.itsm.resolveit}) contains a domain
 * class that imports a Spring annotation.
 */
class ArchitectureRulesEnforcementTest {

    @Test
    void architectureRulesAreEnforced() {
        JavaClasses fixture = new ClassFileImporter().importPackages("archfixtures.cleanarch");

        EvaluationResult result = ArchitectureRules.DOMAIN_IS_FRAMEWORK_FREE.evaluate(fixture);

        assertThat(result.hasViolation()).isTrue();
        assertThat(result.getFailureReport().toString())
                .contains("TicketWithSpringAnnotation")
                .contains("org.springframework.stereotype.Component");
    }
}
