package com.itsm.resolveit.incident.adapters.in.web;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Body of {@code POST /api/v1/tickets}. Transport checks (required, length, known codes); an invalid
 * request gets {@code VALIDATION_FAILED} with the field names in {@code params.fields}. The sizes here are
 * only a generous transport guard (4x); the trimmed limits (title 120, description 2000) are the value
 * objects' rules.
 */
@Schema(description = "The incident to report")
record ReportIncidentRequest(
        @NotBlank @Size(max = 480) @Schema(example = "Laptop won't start", maxLength = 120) String title,
        @NotBlank @Size(max = 8000) @Schema(example = "The power LED blinks, the screen stays black.", maxLength = 2000)
        String description,
        @NotBlank @Pattern(regexp = "HARDWARE|SOFTWARE|NETWORK|ACCESS|OTHER")
        @Schema(allowableValues = {"HARDWARE", "SOFTWARE", "NETWORK", "ACCESS", "OTHER"}) String category,
        @NotBlank @Pattern(regexp = "LOW|MEDIUM|HIGH|CRITICAL")
        @Schema(allowableValues = {"LOW", "MEDIUM", "HIGH", "CRITICAL"}) String priority) {
}
