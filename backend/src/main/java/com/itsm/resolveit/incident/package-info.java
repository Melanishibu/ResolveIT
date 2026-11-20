/**
 * Incident bounded context: incidents, ticket numbers, assignment, lifecycle, comments, incident audit history and the dashboard read model.
 *
 * <p>Spring Modulith application module, persisted in its own PostgreSQL schema {@code incident}.
 * Other modules may use only types in this package (the published API and integration events);
 * every sub-package is internal.
 */
@ApplicationModule(displayName = "Incident")
package com.itsm.resolveit.incident;

import org.springframework.modulith.ApplicationModule;
