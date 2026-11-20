package com.itsm.resolveit;

import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.shared.error.ErrorCodeRegistry;
import com.itsm.resolveit.shared.error.RegisteredErrorCode;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.SerializationFeature;
import tools.jackson.databind.json.JsonMapper;

/**
 * Keeps the published error-code contract {@code contracts/error-codes.json} in step with
 * {@link ErrorCodeRegistry}. The frontend catalogue gate (RIT-US-02) reads that file.
 */
class ErrorCodeContractTest {

    static final Path CONTRACT = Path.of("..", "contracts", "error-codes.json");
    static final String REGENERATE_COMMAND =
            "cd backend; .\\mvnw.cmd test \"-Dtest=ErrorCodeContractTest\" \"-DupdateContracts=true\"";

    private static final JsonMapper JSON = JsonMapper.builder().enable(SerializationFeature.INDENT_OUTPUT).build();

    @Test
    void errorCodeContractFileIsUpToDate() throws IOException {
        String expected = render();
        if (Boolean.getBoolean("updateContracts")) {
            Files.createDirectories(CONTRACT.getParent());
            Files.writeString(CONTRACT, expected, StandardCharsets.UTF_8);
        }

        String actual = Files.exists(CONTRACT) ? normalise(Files.readString(CONTRACT, StandardCharsets.UTF_8)) : "<missing>";

        assertThat(actual)
                .as("contracts/error-codes.json is out of date with ErrorCodeRegistry. Regenerate it from the repo root with:%n  %s%nand commit the result.",
                        REGENERATE_COMMAND)
                .isEqualTo(expected);
    }

    static String render() {
        List<Map<String, Object>> codes = ErrorCodeRegistry.all().stream().map(ErrorCodeContractTest::toJson).toList();
        Map<String, Object> document = new LinkedHashMap<>();
        document.put("description", "ResolveIT error-code registry. Generated from ErrorCodeRegistry; do not edit by hand. Regenerate: "
                + REGENERATE_COMMAND);
        document.put("errorCodes", codes);
        return normalise(JSON.writeValueAsString(document));
    }

    private static Map<String, Object> toJson(RegisteredErrorCode entry) {
        Map<String, Object> json = new LinkedHashMap<>();
        json.put("code", entry.code());
        json.put("httpStatus", entry.httpStatus());
        json.put("requiredParams", List.copyOf(entry.sortedRequiredParams()));
        json.put("title", entry.title());
        json.put("why", entry.why());
        json.put("nextStep", entry.nextStep());
        return json;
    }

    /** LF line endings and exactly one trailing newline, so the file is identical on Windows and Linux CI. */
    private static String normalise(String text) {
        return text.replace("\r\n", "\n").stripTrailing() + "\n";
    }
}
