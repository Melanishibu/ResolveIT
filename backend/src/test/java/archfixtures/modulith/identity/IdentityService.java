package archfixtures.modulith.identity;

import archfixtures.modulith.incident.domain.IncidentInternal;

/**
 * DELIBERATE VIOLATION – test fixture for ModuleBoundaryEnforcementTest.
 * The identity module uses an internal class of the incident module.
 */
public class IdentityService {

    private final IncidentInternal leakedInternal = new IncidentInternal();

    public IncidentInternal leakedInternal() {
        return leakedInternal;
    }
}
