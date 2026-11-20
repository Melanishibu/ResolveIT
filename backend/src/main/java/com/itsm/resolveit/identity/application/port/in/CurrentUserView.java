package com.itsm.resolveit.identity.application.port.in;

import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserId;

/** What the app may know about the logged-in user: never the password hash or lockout state. */
public record CurrentUserView(UserId id, DisplayName name, EmailAddress email, Role role) {

    public static CurrentUserView of(User user) {
        return new CurrentUserView(user.id(), user.displayName(), user.email(), user.role());
    }
}
