package com.itsm.resolveit.shared.error;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

class ErrorCodeRegistryTest {

    private static final Pattern PLACEHOLDER = Pattern.compile("\\{(\\w+)}");

    @Test
    void containsEveryPlatformErrorCode() {
        for (PlatformErrorCode code : PlatformErrorCode.values()) {
            assertThat(ErrorCodeRegistry.find(code.code())).as(code.code()).isPresent();
        }
    }

    @Test
    void messagesOnlyUseTheirRequiredParams() {
        for (RegisteredErrorCode entry : ErrorCodeRegistry.all()) {
            assertThat(placeholders(entry.why() + " " + entry.nextStep()))
                    .as("placeholders of %s", entry.code())
                    .isSubsetOf(entry.requiredParams());
        }
    }

    @Test
    void listsCodesSortedAndUnique() {
        var codes = ErrorCodeRegistry.all().stream().map(RegisteredErrorCode::code).toList();

        assertThat(codes).isSorted().doesNotHaveDuplicates();
    }

    @Test
    void rejectsAnEntryWithoutNextStep() {
        assertThatThrownBy(() -> new RegisteredErrorCode("SOME_CODE", 422, Set.of(), "Title", "Why", " "))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("nextStep");
    }

    @Test
    void rejectsACodeThatIsNotUpperSnakeCase() {
        assertThatThrownBy(() -> new RegisteredErrorCode("someCode", 422, Set.of(), "Title", "Why", "Next"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("UPPER_SNAKE_CASE");
    }

    private static Set<String> placeholders(String text) {
        Set<String> names = new TreeSet<>();
        Matcher matcher = PLACEHOLDER.matcher(text);
        while (matcher.find()) {
            names.add(matcher.group(1));
        }
        return names;
    }
}
