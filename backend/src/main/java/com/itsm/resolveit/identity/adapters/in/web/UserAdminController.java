package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.application.port.in.CreateUserCommand;
import com.itsm.resolveit.identity.application.port.in.ChangeUserStatusUseCase;
import com.itsm.resolveit.identity.application.port.in.CreateUserUseCase;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
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

/** User management for Admins: create (RIT-US-06), list and activate/deactivate (RIT-US-08). */
@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "User management", description = "Admins create Technicians and Employees, who get an invitation email")
class UserAdminController {

    private final CreateUserUseCase createUser;
    private final ListUsersQuery listUsers;
    private final ChangeUserStatusUseCase changeStatus;
    private final com.itsm.resolveit.identity.application.port.in.ResendInvitationUseCase resendInvitation;

    UserAdminController(CreateUserUseCase createUser, ListUsersQuery listUsers, ChangeUserStatusUseCase changeStatus,
                        com.itsm.resolveit.identity.application.port.in.ResendInvitationUseCase resendInvitation) {
        this.createUser = createUser;
        this.listUsers = listUsers;
        this.changeStatus = changeStatus;
        this.resendInvitation = resendInvitation;
    }

    @GetMapping
    @Operation(summary = "List users (Admin)",
            description = "Filters role, active and q (name or email, case-insensitive); page 0-based, size 1–100"
                    + " (default 20), sort name|email|role|department,asc|desc (default name,asc). invitationStatus is"
                    + " derived from the latest invitation.",
            security = @SecurityRequirement(name = SessionCookies.SESSION_COOKIE))
    @ApiResponse(responseCode = "200", description = "A page of users")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED (role, page, size or sort)",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "403", description = "AUTH_FORBIDDEN (not an Admin)",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    UserListResponse list(Actor actor,
                          @RequestParam(required = false) String role,
                          @RequestParam(required = false) Boolean active,
                          @RequestParam(required = false) String q,
                          @RequestParam(defaultValue = "0") int page,
                          @RequestParam(defaultValue = "" + ListUsersQuery.Criteria.DEFAULT_SIZE) int size,
                          @RequestParam(defaultValue = "name,asc") String sort) {
        Optional<Role> roleFilter = role == null || role.isBlank()
                ? Optional.empty()
                : Optional.of(field("role", () -> Role.valueOf(role.strip())));
        String[] sortParts = sort.split(",", -1);
        ListUsersQuery.SortField sortField = field("sort",
                () -> ListUsersQuery.SortField.valueOf(sortParts[0].strip().toUpperCase(Locale.ROOT)));
        boolean ascending = sortParts.length < 2 || !sortParts[1].strip().equalsIgnoreCase("desc");
        if (sortParts.length > 2 || (sortParts.length == 2 && !sortParts[1].strip().matches("(?i)asc|desc"))) {
            throw new InvalidFieldException("sort");
        }
        ListUsersQuery.Criteria criteria = field(page < 0 ? "page" : "size", () -> new ListUsersQuery.Criteria(
                roleFilter, Optional.ofNullable(active), Optional.ofNullable(q), page, size, sortField, ascending));
        return UserListResponse.of(listUsers.list(actor, criteria));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Activate or deactivate a user (Admin)",
            description = "Deactivated users cannot log in, and their sessions are refused on the next request. An"
                    + " Admin cannot deactivate themselves. Audited as USER_DEACTIVATED / USER_ACTIVATED.",
            security = @SecurityRequirement(name = SessionCookies.SESSION_COOKIE))
    @ApiResponse(responseCode = "200", description = "The user's row after the change")
    @ApiResponse(responseCode = "403", description = "AUTH_FORBIDDEN (not an Admin) or AUTH_CSRF_INVALID",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "404", description = "USER_NOT_FOUND",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "409", description = "USER_CANNOT_DEACTIVATE_SELF",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    UserListResponse.Item changeStatus(Actor actor, @PathVariable UUID id,
                                       @Valid @RequestBody ChangeUserStatusRequest request) {
        return UserListResponse.Item.of(changeStatus.changeStatus(
                new ChangeUserStatusUseCase.Command(actor, new UserId(id), request.active())));
    }

    @PostMapping("/{id}/invitation")
    @Operation(summary = "Resend invitation email (Admin)",
            description = "Invalidates all earlier tokens of that user and sends a new 24 h link (RIT-US-22).",
            security = @SecurityRequirement(name = SessionCookies.SESSION_COOKIE))
    @ApiResponse(responseCode = "200", description = "The user's row with updated invitation status")
    @ApiResponse(responseCode = "403", description = "AUTH_FORBIDDEN (not an Admin) or AUTH_CSRF_INVALID",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "404", description = "USER_NOT_FOUND",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "409", description = "USER_ALREADY_ACTIVATED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    UserListResponse.Item resendInvitation(Actor actor, @PathVariable UUID id) {
        return UserListResponse.Item.of(resendInvitation.resend(
                new com.itsm.resolveit.identity.application.port.in.ResendInvitationCommand(actor,
                        new UserId(id))));
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
