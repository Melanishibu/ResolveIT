package com.itsm.resolveit;

import static org.assertj.core.api.Assertions.assertThat;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import org.junit.jupiter.api.Test;

/**
 * Scenario: Unregistered error codes fail the build.
 *
 * <p>Proves the gate in {@link ErrorGateTest} really fails: the fixture package
 * {@code archfixtures.errorgate} (test code, outside {@code com.itsm.resolveit}) contains a domain
 * error whose code is not in the ErrorCode registry.
 */
class ErrorGateEnforcementTest {

    @Test
    void unregisteredErrorCodesFailTheBuild() {
        JavaClasses fixture = new ClassFileImporter().importPackages("archfixtures.errorgate");

        assertThat(ErrorGate.violationsIn(fixture))
                .anySatisfy(violation -> assertThat(violation)
                        .contains("FIXTURE_UNREGISTERED_CODE")
                        .contains("is not registered in ErrorCodeRegistry"));
    }

    @Test
    void registeredCodeWithDifferentParamsFailsTheGate() {
        JavaClasses fixture = new ClassFileImporter().importPackages("archfixtures.errorgate");

        assertThat(ErrorGate.violationsIn(fixture))
                .anySatisfy(violation -> assertThat(violation)
                        .contains("RESOURCE_NOT_FOUND")
                        .contains("requires [path]"));
    }
}
