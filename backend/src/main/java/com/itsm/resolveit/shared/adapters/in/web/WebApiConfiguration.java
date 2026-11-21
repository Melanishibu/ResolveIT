package com.itsm.resolveit.shared.adapters.in.web;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * API-wide web settings: CORS and the OpenAPI document header.
 *
 * <p>CORS (common security rules): only the configured frontend origin ({@code FRONTEND_ORIGIN},
 * default {@code http://localhost:5000}) may call the API from a browser, with credentials (cookies).
 */
@Configuration(proxyBeanMethods = false)
class WebApiConfiguration implements WebMvcConfigurer {

    private final String frontendOrigin;

    WebApiConfiguration(@Value("${resolveit.frontend-origin}") String frontendOrigin) {
        this.frontendOrigin = frontendOrigin;
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins(frontendOrigin)
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE")
                .allowedHeaders("Content-Type", "Accept", "X-XSRF-TOKEN")
                .allowCredentials(true)
                .maxAge(3600);
    }

    @Bean
    OpenAPI resolveItOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("ResolveIT API")
                        .version("v1")
                        .description("IT Service Desk and Incident Management REST API. Errors are RFC 9457 Problem"
                                + " Details with a stable code and params (see contracts/error-codes.json)."))
                .components(new Components());
    }
}
