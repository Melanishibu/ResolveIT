package com.itsm.resolveit;

import static org.assertj.core.api.Assertions.assertThat;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import org.junit.jupiter.api.Test;

/** The error gate on the production code. Free-text error bodies are covered by CleanArchitectureTest. */
class ErrorGateTest {

    @Test
    void everyErrorCodeInTheBackendIsRegisteredWithItsRequiredParams() {
        JavaClasses production = new ClassFileImporter()
                .withImportOption(new ImportOption.DoNotIncludeTests())
                .importPackages("com.itsm.resolveit");

        assertThat(ErrorGate.violationsIn(production)).isEmpty();
    }
}
