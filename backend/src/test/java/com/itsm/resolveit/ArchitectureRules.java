package com.itsm.resolveit;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.Architectures.onionArchitecture;

import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.library.GeneralCodingRules;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * The clean-architecture rules (clean-architecture skill, java-spring.md section 5), defined once so
 * they run against the production code ({@link CleanArchitectureTest}) and against deliberately
 * violating fixtures ({@link ArchitectureRulesEnforcementTest}).
 *
 * <p>{@code allowEmptyShould(true)}: the {@code identity} and {@code incident} layers are still
 * empty in RIT-US-01; the rules apply as soon as classes appear.
 */
public final class ArchitectureRules {

    public static final ArchRule DOMAIN_IS_FRAMEWORK_FREE = noClasses()
            .that().resideInAPackage("..domain..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    "org.springframework..", "jakarta..", "javax..", "org.hibernate..",
                    "com.fasterxml..", "tools.jackson..", "org.slf4j..", "lombok..",
                    "..application..", "..adapters..", "..config..")
            .allowEmptyShould(true)
            .because("the domain must compile and run without any framework (clean-architecture §1)");

    public static final ArchRule APPLICATION_HAS_NO_TECHNOLOGY = noClasses()
            .that().resideInAPackage("..application..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    "..adapters..", "..config..", "org.springframework.web..", "org.springframework.data..",
                    "org.springframework.stereotype..", "jakarta.persistence..", "org.hibernate..",
                    "com.fasterxml..", "tools.jackson..")
            .allowEmptyShould(true)
            .because("use cases only orchestrate and know no technology (clean-architecture §1)");

    public static final ArchRule ONION = onionArchitecture()
            .domainModels("..domain.model..", "..domain.event..", "..domain.policy..")
            .domainServices("..domain.service..")
            .applicationServices("..application..")
            .adapter("web", "..adapters.in.web..")
            .adapter("messaging", "..adapters.in.messaging..")
            .adapter("scheduler", "..adapters.in.scheduler..")
            .adapter("persistence", "..adapters.out.persistence..")
            .adapter("integration", "..adapters.out.integration..")
            .withOptionalLayers(true);

    public static final ArchRule NO_FIELD_INJECTION = GeneralCodingRules.NO_CLASSES_SHOULD_USE_FIELD_INJECTION;

    public static final ArchRule JPA_ENTITIES_STAY_IN_PERSISTENCE = classes()
            .that().areAnnotatedWith("jakarta.persistence.Entity")
            .should().resideInAPackage("..adapters.out.persistence..")
            .allowEmptyShould(true);

    public static final ArchRule CONTROLLERS_STAY_IN_WEB = classes()
            .that().areAnnotatedWith(RestController.class)
            .or().areAnnotatedWith(RestControllerAdvice.class)
            .should().resideInAPackage("..adapters.in.web..")
            .allowEmptyShould(true);

    public static final ArchRule SHARED_NEVER_DEPENDS_ON_CONTEXTS = noClasses()
            .that().resideInAPackage("com.itsm.resolveit.shared..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    "com.itsm.resolveit.identity..", "com.itsm.resolveit.incident..")
            .because("the shared module serves every bounded context and must not know any of them");

    public static final ArchRule SHARED_ERROR_TYPES_ARE_PLAIN_JAVA = noClasses()
            .that().resideInAPackage("com.itsm.resolveit.shared.error..")
            .should().dependOnClassesThat().resideOutsideOfPackages("java..", "com.itsm.resolveit.shared.error..")
            .because("domains throw these types, so they must be as framework-free as a domain");

    public static final ArchRule EXCEPTION_HANDLERS_RETURN_PROBLEM_DETAILS = methods()
            .that().areAnnotatedWith(ExceptionHandler.class)
            .should().haveRawReturnType(ProblemDetail.class)
            .allowEmptyShould(true)
            .because("errors are RFC 9457 Problem Details with a registered code, never free text (clean-architecture §3a)");

    private ArchitectureRules() {
    }
}
