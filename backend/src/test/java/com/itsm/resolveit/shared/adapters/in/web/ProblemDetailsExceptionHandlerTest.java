package com.itsm.resolveit.shared.adapters.in.web;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.itsm.resolveit.shared.error.DomainException;
import com.itsm.resolveit.shared.error.PlatformErrorCode;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

class ProblemDetailsExceptionHandlerTest {

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new ThrowingController())
                .setControllerAdvice(new ProblemDetailsExceptionHandler())
                .build();
    }

    @Test
    void domainExceptionIsTranslatedWithItsRegisteredStatusTitleAndParams() throws Exception {
        mockMvc.perform(get("/refusal"))
                .andExpect(status().isNotFound())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"))
                .andExpect(jsonPath("$.title").value("This page or item doesn't exist"))
                .andExpect(jsonPath("$.detail").value("Nothing is available at /somewhere. The link may be outdated or mistyped."))
                .andExpect(jsonPath("$.params.path").value("/somewhere"));
    }

    @Test
    void unexpectedExceptionReturnsInternalErrorWithoutLeakingItsMessage() throws Exception {
        mockMvc.perform(get("/boom"))
                .andExpect(status().isInternalServerError())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.code").value("INTERNAL_ERROR"))
                .andExpect(jsonPath("$.params.traceId").isNotEmpty())
                .andExpect(content().string(org.hamcrest.Matchers.not(
                        org.hamcrest.Matchers.containsString("secret-sql-detail"))));
    }

    @RestController
    static class ThrowingController {

        @GetMapping("/refusal")
        String refusal() {
            throw new SampleRefusal();
        }

        @GetMapping("/boom")
        String boom() {
            throw new IllegalStateException("secret-sql-detail");
        }
    }

    static class SampleRefusal extends DomainException {
        SampleRefusal() {
            super(PlatformErrorCode.RESOURCE_NOT_FOUND, Map.of("path", "/somewhere"));
        }
    }
}
