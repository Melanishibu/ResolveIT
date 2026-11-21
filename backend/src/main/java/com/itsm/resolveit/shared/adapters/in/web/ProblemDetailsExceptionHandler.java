package com.itsm.resolveit.shared.adapters.in.web;

import com.itsm.resolveit.shared.error.DomainException;
import com.itsm.resolveit.shared.error.PlatformErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import tools.jackson.core.JacksonException;

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

    /**
     * A query or path parameter the server cannot convert ({@code ?page=abc}, a malformed id): the client sent
     * invalid input, so 400 VALIDATION_FAILED naming the parameter, not 500 (bug AB#186).
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    ProblemDetail handleParameterTypeMismatch(MethodArgumentTypeMismatchException ex, HttpServletRequest request) {
        return ProblemDetailFactory.create(PlatformErrorCode.VALIDATION_FAILED, Map.of("fields", List.of(ex.getName())),
                request.getRequestURI());
    }

    /**
     * A body that is not readable JSON, or has a field of the wrong type: 400 VALIDATION_FAILED, naming the field
     * where the JSON parser knows it (bug AB#186).
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    ProblemDetail handleUnreadableBody(HttpMessageNotReadableException ex, HttpServletRequest request) {
        return ProblemDetailFactory.create(PlatformErrorCode.VALIDATION_FAILED, Map.of("fields", bodyFields(ex)),
                request.getRequestURI());
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

    /** The JSON property path of the failing field ("active", "items.0.title"), if the parser reported one. */
    private static List<String> bodyFields(HttpMessageNotReadableException ex) {
        for (Throwable cause = ex.getCause(); cause != null; cause = cause.getCause()) {
            if (cause instanceof JacksonException jackson) {
                String path = jackson.getPath().stream()
                        .filter(reference -> reference.getPropertyName() != null || reference.getIndex() >= 0)
                        .map(reference -> reference.getPropertyName() != null
                                ? reference.getPropertyName() : String.valueOf(reference.getIndex()))
                        .collect(Collectors.joining("."));
                return path.isEmpty() ? List.of() : List.of(path);
            }
        }
        return List.of();
    }

    private static List<String> invalidFields(Exception ex) {
        if (ex instanceof BindException bindException) {
            return bindException.getFieldErrors().stream().map(FieldError::getField).distinct().sorted().toList();
        }
        return List.of();
    }
}
