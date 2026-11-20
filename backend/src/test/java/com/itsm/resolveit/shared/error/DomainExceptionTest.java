package com.itsm.resolveit.shared.error;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Map;
import org.junit.jupiter.api.Test;

class DomainExceptionTest {

    @Test
    void carriesItsCodeAndParamsAndUsesTheCodeAsMessage() {
        var refusal = new SampleRefusal(Map.of("path", "/api/v1/incidents/42"));

        assertThat(refusal.errorCode()).isEqualTo(PlatformErrorCode.RESOURCE_NOT_FOUND);
        assertThat(refusal.params()).containsEntry("path", "/api/v1/incidents/42");
        assertThat(refusal.getMessage()).isEqualTo("RESOURCE_NOT_FOUND");
    }

    @Test
    void rejectsMissingRequiredParams() {
        assertThatThrownBy(() -> new SampleRefusal(Map.of()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("RESOURCE_NOT_FOUND")
                .hasMessageContaining("[path]");
    }

    private static final class SampleRefusal extends DomainException {
        SampleRefusal(Map<String, ?> params) {
            super(PlatformErrorCode.RESOURCE_NOT_FOUND, params);
        }
    }
}
