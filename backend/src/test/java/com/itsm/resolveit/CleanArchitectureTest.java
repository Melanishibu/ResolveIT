package com.itsm.resolveit;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/** Runs every architecture rule against the production code; any violation fails the build. */
@AnalyzeClasses(packages = "com.itsm.resolveit", importOptions = ImportOption.DoNotIncludeTests.class)
class CleanArchitectureTest {

    @ArchTest
    static final ArchRule domain_is_framework_free = ArchitectureRules.DOMAIN_IS_FRAMEWORK_FREE;

    @ArchTest
    static final ArchRule application_has_no_technology = ArchitectureRules.APPLICATION_HAS_NO_TECHNOLOGY;

    @ArchTest
    static final ArchRule onion = ArchitectureRules.ONION;

    @ArchTest
    static final ArchRule no_field_injection = ArchitectureRules.NO_FIELD_INJECTION;

    @ArchTest
    static final ArchRule jpa_entities_stay_in_persistence = ArchitectureRules.JPA_ENTITIES_STAY_IN_PERSISTENCE;

    @ArchTest
    static final ArchRule controllers_stay_in_web = ArchitectureRules.CONTROLLERS_STAY_IN_WEB;

    @ArchTest
    static final ArchRule shared_never_depends_on_identity_or_incident = ArchitectureRules.SHARED_NEVER_DEPENDS_ON_CONTEXTS;

    @ArchTest
    static final ArchRule shared_error_types_are_plain_java = ArchitectureRules.SHARED_ERROR_TYPES_ARE_PLAIN_JAVA;

    @ArchTest
    static final ArchRule exception_handlers_return_problem_details = ArchitectureRules.EXCEPTION_HANDLERS_RETURN_PROBLEM_DETAILS;
}
