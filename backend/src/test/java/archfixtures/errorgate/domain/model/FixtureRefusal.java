package archfixtures.errorgate.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** DELIBERATE VIOLATION – a domain error that uses a code missing from the ErrorCode registry. */
public class FixtureRefusal extends DomainException {

    public FixtureRefusal(String ticketNumber) {
        super(FixtureErrorCode.FIXTURE_UNREGISTERED_CODE, Map.of("ticketNumber", ticketNumber));
    }
}
