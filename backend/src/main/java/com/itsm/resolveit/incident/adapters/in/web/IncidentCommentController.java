package com.itsm.resolveit.incident.adapters.in.web;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.application.port.in.IncidentCommentsUseCase;
import com.itsm.resolveit.incident.application.port.in.IncidentCommentsUseCase.CommentPage;
import com.itsm.resolveit.incident.application.port.in.IncidentCommentsUseCase.CommentView;
import com.itsm.resolveit.incident.domain.model.CommentText;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import com.itsm.resolveit.incident.domain.model.IncidentNotFoundException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Comments on an incident (RIT-US-20): add and list, oldest first. No edit or delete. */
@RestController
@RequestMapping("/api/v1/tickets/{id}/comments")
@Tag(name = "Incident comments", description = "Questions and updates that stay with the incident")
class IncidentCommentController {

    private static final String SESSION_SCHEME = "RIT_SESSION";

    private final IncidentCommentsUseCase comments;

    IncidentCommentController(IncidentCommentsUseCase comments) {
        this.comments = comments;
    }

    record AddCommentRequest(@NotBlank @Size(max = 4000) @Schema(maxLength = 1000) String text) {
    }

    record Author(String id, String name) {
    }

    record CommentResponse(String id, Author author, String text, @Schema(description = "ISO-8601 UTC") String createdAt) {

        static CommentResponse of(CommentView view) {
            String authorId = view.comment().authorId().toString();
            return new CommentResponse(view.comment().id().toString(),
                    new Author(authorId, view.author().map(user -> user.name()).orElse(null)),
                    view.comment().text().value(), view.comment().createdAt().toString());
        }
    }

    record CommentPageResponse(List<CommentResponse> items, int page, int size, long totalItems, int totalPages) {

        static CommentPageResponse of(CommentPage page) {
            return new CommentPageResponse(page.items().stream().map(CommentResponse::of).toList(), page.page(),
                    page.size(), page.totalItems(), page.totalPages());
        }
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add a comment", description = "Text 1–1000 characters; the author is the caller.",
            security = @SecurityRequirement(name = SESSION_SCHEME))
    @ApiResponse(responseCode = "201", description = "Created")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "403", description = "INCIDENT_ACCESS_DENIED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "409", description = "INCIDENT_CLOSED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    CommentResponse add(Actor actor, @PathVariable("id") String id, @Valid @RequestBody AddCommentRequest request) {
        CommentText text;
        try {
            text = new CommentText(request.text());
        } catch (IllegalArgumentException invalid) {
            throw new InvalidFieldException("text");
        }
        return CommentResponse.of(comments.add(actor, incidentId(id), text));
    }

    @GetMapping
    @Operation(summary = "List comments", description = "Oldest first; page 0-based, size 1–100 (default 20).",
            security = @SecurityRequirement(name = SESSION_SCHEME))
    @ApiResponse(responseCode = "200", description = "OK")
    @ApiResponse(responseCode = "403", description = "INCIDENT_ACCESS_DENIED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    CommentPageResponse list(Actor actor, @PathVariable("id") String id,
                             @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        if (page < 0) {
            throw new InvalidFieldException("page");
        }
        if (size < 1 || size > 100) {
            throw new InvalidFieldException("size");
        }
        return CommentPageResponse.of(comments.list(actor, incidentId(id), page, size));
    }

    /** A malformed id is answered as not found, like an unknown one. */
    private static IncidentId incidentId(String id) {
        try {
            return new IncidentId(UUID.fromString(id));
        } catch (IllegalArgumentException malformed) {
            throw new IncidentNotFoundException();
        }
    }
}
