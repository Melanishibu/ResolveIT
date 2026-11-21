package com.itsm.resolveit.identity.adapters.in.web;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

/** Body of {@code PATCH /api/v1/users/{id}/status} (RIT-US-08). */
@Schema(description = "The new status")
record ChangeUserStatusRequest(@NotNull @Schema(example = "false") Boolean active) {
}
