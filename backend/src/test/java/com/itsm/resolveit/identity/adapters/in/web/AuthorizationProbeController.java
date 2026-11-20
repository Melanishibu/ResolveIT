package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.Permission;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * TEST ONLY (test sources, never shipped): endpoints that exercise the request protection exactly
 * like a real controller would, so the authorisation harness can prove it before real Admin-only
 * endpoints exist (RIT-US-05).
 */
@RestController
@RequestMapping("/api/v1/test-probe")
class AuthorizationProbeController {

    /** Admin-only, like user management: the use case would call actor.require(MANAGE_USERS). */
    @GetMapping("/admin-only")
    Map<String, String> adminOnly(Actor actor) {
        actor.require(Permission.MANAGE_USERS);
        return Map.of("role", actor.role().name());
    }

    /** Any logged-in role, state-changing: needs the CSRF token. */
    @PostMapping("/state-change")
    Map<String, String> stateChange(Actor actor) {
        return Map.of("role", actor.role().name());
    }
}
