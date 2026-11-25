package com.itsm.resolveit;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;

/** Spring Modulith verification of the production modules: no cycles, no access to other modules' internals. */
class ModularityTest {

    @Test
    void boundedContextsRespectModuleBoundaries() {
        ApplicationModules.of(ResolveItApplication.class).verify();
    }
}
