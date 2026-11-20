package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.application.port.in.CreateUserCommand;
import com.itsm.resolveit.identity.application.port.in.CreateUserUseCase;
import com.itsm.resolveit.identity.domain.model.Department;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.Role;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.function.Supplier;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** User management for Admins (RIT-US-06 create; list and activation follow in RIT-US-08). */
@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "User management", description = "Admins create Technicians and Employees, who get an invitation email")
class UserAdminController {

    private final CreateUserUseCase createUser;

    UserAdminController(CreateUserUseCase createUser) {
        this.createUser = createUser;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a Technician or Employee and send an invitation email",
            description = "The user is created active with no password. The invitation email (link valid 24 h,"
                    + " single use) is sent after the commit; if sending fails the user stays and the invitation"
                    + " status is SEND_FAILED.",
            security = @SecurityRequirement(name = SessionCookies.SESSION_COOKIE))
    @ApiResponse(responseCode = "201", description = "Created")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED or USER_ROLE_NOT_ALLOWED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "403", description = "AUTH_FORBIDDEN (not an Admin) or AUTH_CSRF_INVALID",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "409", description = "USER_EMAIL_TAKEN",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    CreatedUserResponse create(Actor actor, @Valid @RequestBody CreateUserRequest request) {
        CreateUserCommand command = new CreateUserCommand(actor,
                field("name", () -> new DisplayName(request.name())),
                field("email", () -> new EmailAddress(request.email())),
                Role.valueOf(request.role()),
                field("department", () -> new Department(request.department())));
        return CreatedUserResponse.of(createUser.create(command));
    }

    /** Builds a value object; a value the domain rejects becomes VALIDATION_FAILED for that field. */
    private static <T> T field(String name, Supplier<T> valueObject) {
        try {
            return valueObject.get();
        } catch (IllegalArgumentException invalid) {
            throw new InvalidFieldException(name);
        }
    }
}
