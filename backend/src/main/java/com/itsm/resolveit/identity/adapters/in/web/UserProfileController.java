package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.application.port.in.CurrentUserView;
import com.itsm.resolveit.identity.application.port.in.GetMyProfileUseCase;
import com.itsm.resolveit.identity.application.port.in.UserProfileView;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Objects;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Current user profile endpoints (RIT-US-27). Paths are relative to {@code /api/v1/users}. */
@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "Profile", description = "Current user profile information")
class UserProfileController {

    private final GetMyProfileUseCase getMyProfile;

    UserProfileController(GetMyProfileUseCase getMyProfile) {
        this.getMyProfile = Objects.requireNonNull(getMyProfile, "getMyProfile");
    }

    @GetMapping("/me")
    @Operation(summary = "My profile",
            description = "Returns name, email, role (UI label), department, member since. Read-only in PI_01."
                    + " Every authenticated user may read their own profile.",
            security = @SecurityRequirement(name = SessionCookies.SESSION_COOKIE))
    @ApiResponse(responseCode = "200", description = "Profile data")
    @ApiResponse(responseCode = "401", description = "AUTH_UNAUTHENTICATED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    UserProfileResponse me(CurrentUserView user) {
        UserProfileView profile = getMyProfile.getMyProfile(user.id());
        return UserProfileResponse.of(profile);
    }
}
