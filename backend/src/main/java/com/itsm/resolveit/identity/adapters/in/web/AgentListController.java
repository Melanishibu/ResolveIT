package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.Permission;
import com.itsm.resolveit.identity.UserLookup;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** The active Support Agents an Admin can assign incidents to (RIT-US-14). */
@RestController
@Tag(name = "User management")
class AgentListController {

    private final UserLookup users;

    AgentListController(UserLookup users) {
        this.users = users;
    }

    record AgentResponse(String id, String name, String email) {
    }

    @GetMapping("/api/v1/users/agents")
    @Operation(summary = "List assignable agents (Admin)", description = "Active Support Agents, by name.",
            security = @SecurityRequirement(name = "RIT_SESSION"))
    @ApiResponse(responseCode = "200", description = "OK")
    @ApiResponse(responseCode = "403", description = "AUTH_FORBIDDEN (not an Admin)",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    List<AgentResponse> agents(Actor actor) {
        actor.require(Permission.ASSIGN_INCIDENT);
        return users.activeSupportAgents().stream()
                .map(agent -> new AgentResponse(agent.id().toString(), agent.name(), agent.email()))
                .toList();
    }
}
