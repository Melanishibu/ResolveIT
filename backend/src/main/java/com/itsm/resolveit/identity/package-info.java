/**
 * Identity bounded context: users, roles, credentials, sessions, invitations, password tokens, login attempts and the user audit log.
 *
 * <p>Spring Modulith application module, persisted in its own PostgreSQL schema {@code identity}.
 * Other modules may use only types in this package (the published API and integration events);
 * every sub-package is internal.
 */
@ApplicationModule(displayName = "Identity")
package com.itsm.resolveit.identity;

import org.springframework.modulith.ApplicationModule;
