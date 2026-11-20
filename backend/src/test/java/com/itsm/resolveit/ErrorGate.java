package com.itsm.resolveit;

import com.itsm.resolveit.shared.error.ErrorCode;
import com.itsm.resolveit.shared.error.ErrorCodeRegistry;
import com.itsm.resolveit.shared.error.RegisteredErrorCode;
import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.domain.JavaModifier;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.TreeSet;

/**
 * The backend error-message gate (clean-architecture §3a): every {@link ErrorCode} that code can
 * throw or return must be registered in {@link ErrorCodeRegistry} with the same required params.
 */
final class ErrorGate {

    private ErrorGate() {
    }

    /** Returns one readable line per violation; empty when the gate passes. */
    static List<String> violationsIn(JavaClasses classes) {
        List<String> violations = new ArrayList<>();
        for (JavaClass javaClass : classes) {
            if (!isErrorCodeImplementation(javaClass)) {
                continue;
            }
            if (!javaClass.isEnum()) {
                violations.add(javaClass.getName() + " implements ErrorCode but is not an enum;"
                        + " declare error codes as enum constants so the gate can check them.");
                continue;
            }
            for (Object constant : javaClass.reflect().getEnumConstants()) {
                checkRegistered(javaClass, (ErrorCode) constant, violations);
            }
        }
        return violations;
    }

    private static boolean isErrorCodeImplementation(JavaClass javaClass) {
        return javaClass.isAssignableTo(ErrorCode.class)
                && !javaClass.isInterface()
                && !javaClass.isAnonymousClass()
                && !javaClass.getModifiers().contains(JavaModifier.ABSTRACT);
    }

    private static void checkRegistered(JavaClass owner, ErrorCode errorCode, List<String> violations) {
        Optional<RegisteredErrorCode> entry = ErrorCodeRegistry.find(errorCode.code());
        if (entry.isEmpty()) {
            violations.add("Error code " + errorCode.code() + " (" + owner.getSimpleName()
                    + ") is not registered in ErrorCodeRegistry. Register it with HTTP status, required params,"
                    + " title, why and next step, then regenerate contracts/error-codes.json.");
            return;
        }
        if (!entry.get().requiredParams().equals(errorCode.requiredParams())) {
            violations.add("Error code " + errorCode.code() + " (" + owner.getSimpleName() + ") declares params "
                    + new TreeSet<>(errorCode.requiredParams()) + " but ErrorCodeRegistry requires "
                    + entry.get().sortedRequiredParams() + ".");
        }
    }
}
