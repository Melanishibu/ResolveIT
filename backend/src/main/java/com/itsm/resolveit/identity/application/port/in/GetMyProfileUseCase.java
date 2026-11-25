package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.model.UserId;

/** Inbound port to read the logged-in user's profile (RIT-US-27). */
public interface GetMyProfileUseCase {

    UserProfileView getMyProfile(UserId userId);
}
