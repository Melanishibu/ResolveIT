package com.itsm.resolveit.shared.adapters.in.web;

import com.itsm.resolveit.shared.error.DomainException;
import com.itsm.resolveit.shared.error.PlatformErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Translates every error that reaches Spring MVC into RFC 9457 Problem Details with a registered
 * {@code code} and its {@code params}. Never exposes stack traces, SQL or exception messages.
 */
@RestControllerAdvice
class ProblemDetailsExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ProblemDetailsExceptionHandler.class);

    @ExceptionHandler(DomainException.class)
    ProblemDetail handleDomainException(DomainException ex, HttpServletRequest request) {
        return ProblemDetailFactory.create(ex.errorCode(), ex.params(), request.getRequestURI());
    }

    @ExceptionHandler(Exception.class)
    ProblemDetail handleOtherException(Exception ex, HttpServletRequest request) {
        String path = request.getRequestURI();
        if (ex instanceof ErrorResponse errorResponse && errorResponse.getStatusCode().is4xxClientError()) {
            return clientError(errorResponse.getStatusCode(), ex, request.getMethod(), path);
        }
        String traceId = UUID.randomUUID().toString();
        log.error("Unexpected error, traceId={}, path={}", traceId, path, ex);
        return ProblemDetailFactory.create(PlatformErrorCode.INTERNAL_ERROR, Map.of("traceId", traceId), path);
    }

    private static ProblemDetail clientError(HttpStatusCode status, Exception ex, String method, String path) {
        return switch (status.value()) {
            case 404 -> ProblemDetailFactory.create(PlatformErrorCode.RESOURCE_NOT_FOUND, Map.of("path", path), path);
            case 405 -> ProblemDetailFactory.create(
                    PlatformErrorCode.METHOD_NOT_ALLOWED, Map.of("method", method, "path", path), path);
            case 400 -> ProblemDetailFactory.create(
                    PlatformErrorCode.VALIDATION_FAILED, Map.of("fields", invalidFields(ex)), path);
            default -> ProblemDetailFactory.create(PlatformErrorCode.REQUEST_NOT_SUPPORTED, Map.of("path", path), path);
        };
    }

    private static List<String> invalidFields(Exception ex) {
        if (ex instanceof BindException bindException) {
            return bindException.getFieldErrors().stream().map(FieldError::getField).distinct().sorted().toList();
        }
        return List.of();
    }
}
