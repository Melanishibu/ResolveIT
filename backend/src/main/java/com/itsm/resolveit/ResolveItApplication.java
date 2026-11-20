package com.itsm.resolveit;

import java.time.ZoneOffset;
import java.util.TimeZone;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Composition root of the ResolveIT backend.
 *
 * <p>Each direct sub-package is a Spring Modulith application module (one bounded context, one
 * PostgreSQL schema): {@code identity}, {@code incident}, plus the open {@code shared} module that
 * holds only the error types and the Problem Details web handler.
 */
@SpringBootApplication
public class ResolveItApplication {

    public static void main(String[] args) {
        // API convention: timestamps are UTC. Also avoids legacy JVM zone ids (e.g. "Asia/Calcutta" on
        // Windows) that PostgreSQL 17 rejects when the JDBC driver sends the session TimeZone.
        TimeZone.setDefault(TimeZone.getTimeZone(ZoneOffset.UTC));
        SpringApplication.run(ResolveItApplication.class, args);
    }
}
