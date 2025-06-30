# Integrating applications using a single source of user authentication

## Motivation

The open source ecosystem offers a lot of great tools that serve different user needs. Some tools address very specific use cases,
while others satisfy a greater range of them. For many tools it makes sense to stop growing the number of use cases at some
point and focussing on the ones in its center. On the other hand users have a wide range of problems to be solved and they would
benefit from a strong and deep integration between all the tools they are using in their daily work.

This has been recognized by big tech companies, that try to sell their services as a platform. If you use GMail for your email,
it's easy to import a meeting invite into Google Calendar and from Google calendar it's very easy to create invites for Google Meet. Similarly
Jira works well together with Confluence and both tools allow users to fluently navigate between the two.

Open source applications could benefit from being part of a larger platform as well, since that would make them more accessible to their
users. This requires integrating applications with each other though, the imposed development costs are often one reason to not integrate
with more other applications or to only integrate on a very basic level, that leaves the users to wish for more.

In this document we want to outline which steps are necessary to allow an open source application to be used as part of a bigger platform,
providing a great experience to users while making sure that double work is avoided and thus development effort is used efficiently.
All of them add value for the user, one step at a time, while building on open standards as much as possible, so that the work on one
integration feature can benefit other integration features as well.

## Overview

Let's consider an example where we want to make three applications available to users as a unified platform. Our target setup could look like this:

TODO: Boxes and arrows chart: IDP box at top, below three boxes for Application A to C, each pairwise connected with arrows labeled
      "API call as user". Below them is a pool of users that access different applications (more arrows).

There is a central identity provider that's responsible for signing in users, managing their group and role memberships and knows
about their meta data such as names and email addresses.

The applications integrate to each other via API calls that are performed in the name of the user. This means when application A makes
a request to B, A does not have to filter the information returned by B for things that the user is allowed to see, because the information
returned is already limited to "the perspective" of the user for whom the request was made.

The system works securely, because the authentication information passed from application A for a request to B can't be used by B to make
additional requests to C, limiting the impact that misbehaving or compromised applications can have.

Lastly, all applications know about users in the system even before their first login, because the identity provider used a SCIM client
to provision user accounts ahead-of-time.

The following sections go into some detail on what's required to make this setup possible. Each section introduces a new concept that
adds value to the system and for the user, while following sections enhance what the previous sections introduced.

## Building block: Single Sign-on using OpenID Connect

The first step is to establish single sign-on: One service -- the identity provider -- is responsible to authenticate the user.
All other applications can rely on that. For the users this means they only have to enter their password once to access any of the applications associated to that identity provider. An advantage that applications can later benefit from is that every user will be uniquely identifiable,
thus it's not necessary to rely on weak links such as the email address to determine whether a user account in application A belongs to the
same real user as another user account in application B.

Single sign-on can be achieved through a standard called OpenID Connect, which itself is an extension of the OAuth 2.0 standard.
While OAuth 2.0 just defines how an application can obtain an access token from the identity provider (referred to as authorization
server in the OAuth spec), the OpenID Connect specification defines ways for the application to immediately get information about
the user that has been authenticated, such as their name and email address. This information can be gathered in one of two ways:

* By inspecting the ID token that's returned by the identity provider during authentication
* By making a web request to the UserInfo endpoint of the identity provider using an access token obtained during authentication

Using the ID token has the advantage that no further web requests are necessary, because the ID token is a JSON web token that has
been signed by the identity provider and usually contains the same information as the UserInfo endpoint would return.

From a user's perspective there is not a lot of integration with single sign-on alone. All the applications share a common login interface,
but they can't interact with each other, so each of them is its own walled garden. (TODO: is this a proper ending now that there is another
section before the API section?)

## Building block: SSO session management

How tightly an application and the identity provider are integrated depends on the deployment scenario. In the most simple case
single sign-on aims at a "social login", where a user can use one of their existing accounts at a larger provider to log into an application,
but afterwards the application and the identity provider don't share any further information, because they don't belong to each other. For
example if the user would log out from the identity provider, the application would not notice and not care and vice versa.

When building a common platform, it's usually desirable to do a deeper integration. I.e. when the user logs out from the identity provider,
the application should log the user out as well and when a user logs out from an application, they should be logged out from the identity
provider. This ensures that there is not only a single sign-on, but also a single logout: Logging out of one application, logs the user
out of all applications.

TODO: Talk about back-channel logout and session handling

TODO: Additional benefit -> access tokens and refresh tokens are guaranteed to keep working

## Building block: Authenticating API calls among applications

The design of APIs can be different depending on what the API is supposed to be used for. For user-facing integrations it usually makes
sense to perform regular permissions and visibility checks in the API as well. For example if an application is managing the task list
of a user it might offer an endpoint `/api/tasks/me` that would return the tasks for the authenticated user of the API request.

If you looked at the OAuth 2.0 specifications already, you might be aware of how to obtain an access token from an identity
provider. The specification also indicates that such a token can be used to request information from a resource server, for example by passing
it as a Bearer token. However, OAuth 2.0 leaves it up to the implementors of a resource server on how to validate a token received this way.
This gap is closed by RFC 9068 which defines the so-called "JWT Profile for OAuth 2.0 Access Tokens", which specifies previous best practices
as a standard way to validate access tokens. It does so by building on top of existing standards, such as OpenID Connect that most likely led to
the emergence of those best practices in the first place.

The essential idea of RFC 9068 is that access tokens can be JSON Web Tokens (JWT) as well, that are signed by the authorization server. It defines
how certain claims of the JWT must be interpreted and validated, so that the resource server can be sure that the token is supposed to be used
for the current API request.

Let's have a look at three of those claims for now:

`sub`
: Identifies the entity on whose behalf the request is made, the so-called subject. In most cases this identifies the user of our platform. The identifier used here should be the same as the one that's indicated as a `sub` in the ID token of a user during authentication.

`aud`
: The so-called audience claim indicates for which applications the token is intended. For a request to the API of application B, this should include the client identifier of application B.

`scope`
: Scopes indicate the capabilities of a token. Applications use them differently, but they usually limit what a token is capable of doing. For example you might want to limit certain API calls to tokens that carry a specific scope.

A resource server doesn't need to care how an API client got into possession of such a token, but the subject tells it that the request is made
in the name and with the usual permissions of the indicated user, while the audience indicates that it is indeed a token to be used at the resource
server, while the scope gives the resource server a way to define more fine grained access control apart from that.

One deployment scenario that's made possible through this kind of validation is that the access tokens handed out during single sign-on already
contain the audience for all relevant applications. For example if application A needs to make API calls to B and C, the identity provider is configured
to hand out access tokens with the audiences for B and C when a user signs in to application A. The application can then use the access token
it received during sign-on to make API calls to other applications in the name of the user that signed on. It can use these access tokens as long
as the identity provider is willing to refresh them.

TODO: maybe add an illustration of that scenario

This simple deployment however introduces a risk: If application A receives a token with application B and C in the audience, it means that application
B will receive a token to authenticate requests to it, that includes the audience of application C as well. So even if application B would have no
reason to ever access C, it would now be capable of doing so. This may be a problem depending on the threat model of your platform. This is where token
exchange can help us to mitigate this risk.

## Building block: Using token exchange to limit audiences of a token

The "OAuth 2.0 Token Exchange" is specified in RFC 8693 and allows applications to exchange one token for another token for various different use cases.
The one that we are interested in is often refered to as internal-to-internal token exchange. In this flow a client can exchange a token
that it received from the identity provider for another token that the identity provider created.

This can be used to take the token received during a user's sign-on and exchange it for a token with fewer audiences (if the initial token already
contained multiple audiences) or with more audiences (if the initial token did not have the relevant audience). In our example from above, this
would allow application A to exchange a token that **only** has application B in the audience, before it makes a request to application B. Thus
it can ensure, that application B can't misuse the token.

Support for token exchange is only required from the client application and the identity provider. The resource server does not need to
know how exactly the token was obtained and that a token exchange was involved. It merely has to check every token for the correct
audience claim, which it has to do regardless of token exchange.

## Building block: Provisioning users with SCIM

Another practical problem that might be encountered during the building of a multi-application platform is to provision users in a timely manner.
Assuming single sign-on was already implemented, it's easy for any user that's known to the identity provider to log into an application.
Usually the login is also when information about the user is shared with the application and thus the local user account is created
inside the application.

However, imagine an application has a feature to share some data with another user, for that the user can select the other person to share the data with from a dropdown. Now if the second user never logged into the application, the dropdown will probably not make them selectable, because
no local user account exists for them.

The System for Cross-domain Identity Management (short "SCIM") provides one solution to this problem. It's a push-based approach, where the identity
provider (or a service that's closely tied to it) will proactively send updates about users to applications that implement the
SCIM server API. So for example after new users are created, the SCIM client could notify all applications in the platform about the new users,
effectively making it possible for them to be selected from dropdowns and also allowing one application where the user logged in to already make
API calls to other applications in the name of the user, even that user never logged into the other application yet.

Compared to polling-based solutions like LDAP synchronization, the main advantage is the reduced provisioning delay, because the network calls
are made when the changes to the userbase happen instead of periodically. This can also lead to a reduction in network traffic.

Ideally authentication of SCIM API calls happens through the same mechanisms established for app-to-app API calls already: JSON web tokens obtained
from and signed by the identity provider. However this is not supported by all SCIM clients yet and sometimes it's necessary to use pre-shared keys
(i.e. single-purpose tokens) instead.

## Outlook and limitations

TODO: Session duration and expiring refresh tokens (if not discussed earlier)

## References

* [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html)
* [RFC 6749 - OAuth 2.0](https://www.rfc-editor.org/rfc/rfc6749)
* [RFC 6750 - Bearer Tokens](https://www.rfc-editor.org/rfc/rfc6750)
* [RFC 9068 - JWT Profile for OAuth 2.0 Access Tokens](https://www.rfc-editor.org/rfc/rfc9068)
* [RFC 8693 - OAuth 2.0 Token Exchange](https://www.rfc-editor.org/rfc/rfc8693)
* [RFC 7643 - SCIM: Core Schema](https://www.rfc-editor.org/rfc/rfc7643)
* [RFC 7644 - SCIM: Protocol](https://www.rfc-editor.org/rfc/rfc7644)

## Editorial TODO list:

* Where to put this document eventually? Is it one page under `docs` or should it be placed elsewhere?
* How much name-dropping should we do? Should Keycloak be mentioned as IDP? Should examples go around the project-management sphere?
