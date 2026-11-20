package com.itsm.resolveit.shared.adapters.in.web;

import com.itsm.resolveit.shared.error.ErrorCode;
import com.itsm.resolveit.shared.error.ErrorCodeRegistry;
import com.itsm.resolveit.shared.error.RegisteredErrorCode;
import java.net.URI;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;
import org.springframework.http.ProblemDetail;

/** Builds RFC 9457 Problem Details from a registered error code and its params. */
final class ProblemDetailFactory {

    private ProblemDetailFactory() {
    }

    static ProblemDetail create(ErrorCode errorCode, Map<String, ?> params, String path) {
        RegisteredErrorCode entry = ErrorCodeRegistry.entryFor(errorCode);
        Set<String> missing = new TreeSet<>(entry.requiredParams());
        missing.removeAll(params.keySet());
        if (!missing.isEmpty()) {
            throw new IllegalStateException(
                    "Error code " + entry.code() + " is missing required params " + missing);
        }
        ProblemDetail problem = ProblemDetail.forStatus(entry.httpStatus());
        problem.setTitle(entry.title());
        problem.setDetail(interpolate(entry.why(), params));
        problem.setInstance(URI.create(path));
        problem.setProperty("code", entry.code());
        problem.setProperty("params", new TreeMap<>(params));
        return problem;
    }

    private static String interpolate(String template, Map<String, ?> params) {
        String result = template;
        for (Map.Entry<String, ?> param : params.entrySet()) {
            result = result.replace("{" + param.getKey() + "}", display(param.getValue()));
        }
        return result;
    }

    private static String display(Object value) {
        if (value instanceof Iterable<?> values) {
            return StreamSupport.stream(values.spliterator(), false)
                    .map(String::valueOf)
                    .collect(Collectors.joining(", "));
        }
        return String.valueOf(value);
    }
}
