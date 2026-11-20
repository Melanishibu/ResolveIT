package com.itsm.resolveit.identity.application.port.out;

import com.itsm.resolveit.identity.domain.model.NewPassword;
import com.itsm.resolveit.identity.domain.model.PasswordHash;

/** Turns a new password into the one-way hash that is stored (common rules: BCrypt). */
public interface PasswordHasher {

    PasswordHash hash(NewPassword password);
}
