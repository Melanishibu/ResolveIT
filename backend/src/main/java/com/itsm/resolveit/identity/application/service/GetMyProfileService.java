package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.in.GetMyProfileUseCase;
import com.itsm.resolveit.identity.application.port.in.UserProfileView;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.domain.model.UserId;
import com.itsm.resolveit.identity.domain.model.UserNotFoundException;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/** Loads the profile of the current user (RIT-US-27). */
public class GetMyProfileService implements GetMyProfileUseCase {

    private final UserRepository users;

    public GetMyProfileService(UserRepository users) {
        this.users = Objects.requireNonNull(users, "users");
    }

    @Transactional(readOnly = true)
    @Override
    public UserProfileView getMyProfile(UserId userId) {
        return users.findById(userId)
                .map(u -> new UserProfileView(
                        u.id(),
                        u.displayName(),
                        u.email(),
                        u.role(),
                        u.department(),
                        u.createdAt()))
                .orElseThrow(() -> new UserNotFoundException(userId));
    }
}
