package com.itsm.resolveit.identity.application.port.in;

/**
 * Use case: an Admin creates a Support Agent or Employee, who gets an invitation email (RIT-US-06).
 *
 * <p>Refusals: {@code AccessDeniedException} (403, not an Admin), {@code UserEmailTakenException}
 * (409), {@code UserRoleNotAllowedException} (400).
 */
public interface CreateUserUseCase {

    CreatedUserView create(CreateUserCommand command);
}
