package com.itsm.resolveit.incident.adapters.out.persistence;

import com.itsm.resolveit.incident.application.port.out.IncidentCommentRepository;
import com.itsm.resolveit.incident.domain.model.CommentText;
import com.itsm.resolveit.incident.domain.model.IncidentComment;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;

/** {@link IncidentCommentRepository} on table {@code incident.incident_comment}. */
public class JdbcIncidentCommentRepository implements IncidentCommentRepository {

    private final JdbcClient jdbc;

    public JdbcIncidentCommentRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void append(IncidentComment comment) {
        jdbc.sql("INSERT INTO incident.incident_comment (id, incident_id, author_id, text, created_at)"
                        + " VALUES (:id, :incidentId, :authorId, :text, :createdAt)")
                .param("id", comment.id())
                .param("incidentId", comment.incidentId().value())
                .param("authorId", comment.authorId())
                .param("text", comment.text().value())
                .param("createdAt", comment.createdAt().atOffset(ZoneOffset.UTC))
                .update();
    }

    @Override
    public Page page(IncidentId incidentId, int page, int size) {
        long total = jdbc.sql("SELECT count(*) FROM incident.incident_comment WHERE incident_id = :id")
                .param("id", incidentId.value()).query(Long.class).single();
        var rows = jdbc.sql("SELECT id, author_id, text, created_at FROM incident.incident_comment"
                        + " WHERE incident_id = :id ORDER BY created_at, id LIMIT :limit OFFSET :offset")
                .param("id", incidentId.value()).param("limit", size).param("offset", (long) page * size)
                .query((row, n) -> new IncidentComment(row.getObject("id", UUID.class), incidentId,
                        row.getObject("author_id", UUID.class), new CommentText(row.getString("text")),
                        row.getObject("created_at", OffsetDateTime.class).toInstant()))
                .list();
        return new Page(rows, total);
    }
}
