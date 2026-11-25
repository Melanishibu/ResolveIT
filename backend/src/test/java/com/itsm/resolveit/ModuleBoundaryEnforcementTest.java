package com.itsm.resolveit;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;
import org.springframework.modulith.core.Violations;

/**
 * Scenario: Module boundaries are enforced.
 *
 * <p>Proves the verification in {@link ModularityTest} really fails: in the fixture application
 * {@code archfixtures.modulith} (test code, outside {@code com.itsm.resolveit}) the identity module
 * uses an internal class of the incident module.
 */
class ModuleBoundaryEnforcementTest {

    @Test
    void moduleBoundariesAreEnforced() {
        // The fixture is test code, so it must be imported explicitly (Modulith skips test classes by default).
        ApplicationModules fixture = ApplicationModules.of("archfixtures.modulith", location -> true);

        assertThatThrownBy(fixture::verify)
                .isInstanceOf(Violations.class)
                .hasMessageContaining("IncidentInternal");
    }
}
