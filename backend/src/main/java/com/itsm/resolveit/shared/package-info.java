/**
 * Shared kernel: cross-cutting error infrastructure used by every bounded context.
 *
 * <p>Contains only the plain-Java error types ({@code shared.error}) and the RFC 9457 Problem
 * Details web handler ({@code shared.adapters.in.web}). No business logic, and it never depends on
 * {@code identity} or {@code incident} (enforced by {@code CleanArchitectureTest}).
 */
@ApplicationModule(displayName = "Shared", type = ApplicationModule.Type.OPEN)
package com.itsm.resolveit.shared;

import org.springframework.modulith.ApplicationModule;
