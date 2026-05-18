# `@forgerock/*` Package Selection Guide

## Which packages do I need?

| Scenario | Required packages |
|----------|-----------------|
| Journey (PingAM / PingOne AIC) | `@forgerock/journey-client` + `@forgerock/oidc-client` |
| DaVinci (PingOne) | `@forgerock/davinci-client` |
| DaVinci + token management | `@forgerock/davinci-client` + `@forgerock/oidc-client` |
| OIDC centralized login | `@forgerock/oidc-client` |
| PingOne Protect / behavioral signals | `@forgerock/protect` |
| Device profile, OATH, Push, WebAuthn management | `@forgerock/device-client` |

## Package summaries

### `@forgerock/journey-client`

Callback-based authentication against PingAM or PingOne AIC (formerly AIC). Supports all Journey callback types: Name, Password, Choice, Confirmation, TextInput, TextOutput, KbaCreate, TermsAndConditions, WebAuthn, DeviceProfile, SelectIdp, PingProtect, PollingWait, Redirect, SuspendedTextOutput, and more.

Key API: `journey({ config })` → `client.start()` → `client.next(step)` → check `step.type` for `SuccessStep | FailureStep | Step`.

### `@forgerock/davinci-client`

Collector-based authentication against PingOne DaVinci. Collectors are plain objects (not class instances). Supports TextCollector, PasswordCollector, SubmitCollector, FlowCollector, IdpCollector, SingleSelectCollector, MultiSelectCollector, DeviceRegistrationCollector, DeviceAuthenticationCollector, PhoneNumberCollector, ReadOnlyCollector, ProtectCollector, FidoRegistrationCollector, FidoAuthenticationCollector.

Key API: `davinci({ config })` → `client.start()` → `client.next()` → check `client.getNode().status` for `'continue' | 'success' | 'error'`.

### `@forgerock/oidc-client`

OAuth2/OIDC authorization code flow with PKCE. Handles authorization URL generation, code exchange, token storage, background (silent) renewal via hidden iframe, userinfo fetching, and logout.

Key API: `oidc({ config })` → `client.authorize.url()` → redirect → `client.token.exchange(code, state)` → `client.token.get()`.

### `@forgerock/protect`

PingOne Protect behavioral risk signals. Collects device fingerprint and behavioural data.

Key API: `protect({ envId })` → `signals.start()` → `signals.getData()`.

### `@forgerock/device-client`

Device profile collection and device management (OATH TOTP, Push notifications, WebAuthn registration/authentication, Bound Device). Used alongside Journey or DaVinci for MFA flows requiring device registration.

## Version requirements

All packages are at version **2.0.0** (released 2026-03-19). Requires **Node.js ^20 || ^22 || ^24**.

## Installation

```bash
# Journey + OIDC tokens
npm install @forgerock/journey-client @forgerock/oidc-client

# DaVinci only
npm install @forgerock/davinci-client

# OIDC centralized login
npm install @forgerock/oidc-client

# Optional add-ons
npm install @forgerock/protect
npm install @forgerock/device-client
```
