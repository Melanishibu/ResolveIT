package com.itsm.resolveit.identity.application.port.out;

/** Publishes domain events; listeners that send emails run after the transaction commits. */
public interface DomainEventPublisher {

    void publish(Object event);
}
