package archfixtures.errorgate.domain.model;

import com.itsm.resolveit.shared.error.ErrorCode;
import java.util.Set;

/**
 * DELIBERATE VIOLATIONS – test fixture for ErrorGateEnforcementTest.
 * FIXTURE_UNREGISTERED_CODE is not in the registry; RESOURCE_NOT_FOUND is registered with other params.
 */
public enum FixtureErrorCode implements ErrorCode {

    FIXTURE_UNREGISTERED_CODE(Set.of("ticketNumber")),
    RESOURCE_NOT_FOUND(Set.of("ticketNumber"));

    private final Set<String> requiredParams;

    FixtureErrorCode(Set<String> requiredParams) {
        this.requiredParams = requiredParams;
    }

    @Override
    public String code() {
        return name();
    }

    @Override
    public Set<String> requiredParams() {
        return requiredParams;
    }
}
