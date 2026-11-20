package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.domain.model.Department;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.Role;
import java.util.Objects;

/**
 * Create a user.
 *
 * @param actor      who asks (must be allowed to manage users)
 * @param name       the new user's name
 * @param email      the new user's email (unique, case-insensitive)
 * @param role       SUPPORT_AGENT or EMPLOYEE
 * @param department the department
 */
public record CreateUserCommand(Actor actor, DisplayName name, EmailAddress email, Role role, Department department) {

    public CreateUserCommand {
        Objects.requireNonNull(actor, "actor");
        Objects.requireNonNull(name, "name");
        Objects.requireNonNull(email, "email");
        Objects.requireNonNull(role, "role");
        Objects.requireNonNull(department, "department");
    }
}
