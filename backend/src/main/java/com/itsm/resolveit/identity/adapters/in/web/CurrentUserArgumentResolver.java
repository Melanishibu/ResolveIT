package com.itsm.resolveit.identity.adapters.in.web;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.ActorRole;
import com.itsm.resolveit.identity.application.port.in.CurrentUserView;
import com.itsm.resolveit.identity.domain.model.NotAuthenticatedException;
import com.itsm.resolveit.identity.domain.model.Role;
import org.springframework.core.MethodParameter;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

/**
 * Gives controller methods the authenticated user, set by {@link RequestProtectionInterceptor}:
 * an {@link Actor} parameter (for authorisation in the use case) or a {@link CurrentUserView}.
 */
class CurrentUserArgumentResolver implements HandlerMethodArgumentResolver {

    @Override
    public boolean supportsParameter(MethodParameter parameter) {
        Class<?> type = parameter.getParameterType();
        return type == Actor.class || type == CurrentUserView.class;
    }

    @Override
    public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,
                                  NativeWebRequest webRequest, WebDataBinderFactory binderFactory) {
        Object user = webRequest.getAttribute(RequestProtectionInterceptor.CURRENT_USER_ATTRIBUTE,
                RequestAttributes.SCOPE_REQUEST);
        if (!(user instanceof CurrentUserView view)) {
            // Only possible on a @PublicEndpoint that asks for the user: treat as not logged in.
            throw new NotAuthenticatedException();
        }
        if (parameter.getParameterType() == CurrentUserView.class) {
            return view;
        }
        return new Actor(view.id().value(), actorRole(view.role()));
    }

    /** Explicit mapping: the compiler flags a new domain role that has no published counterpart. */
    static ActorRole actorRole(Role role) {
        return switch (role) {
            case ADMIN -> ActorRole.ADMIN;
            case SUPPORT_AGENT -> ActorRole.SUPPORT_AGENT;
            case EMPLOYEE -> ActorRole.EMPLOYEE;
        };
    }
}
