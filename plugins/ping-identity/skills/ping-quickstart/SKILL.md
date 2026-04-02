---
name: ping-quickstart
description: Use when adding authentication or identity features with Ping Identity — detects the project platform (Android, iOS, JavaScript/Web), explains key Ping Identity concepts and terminology, and routes to the correct Ping Orchestration SDK skill.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# Ping Identity Quickstart

Detect your platform and get started with Ping Identity authentication using the Ping Orchestration SDKs.

---

## Step 1: Detect Your Platform

**Run these commands to identify your project type:**

```bash
# Android (Kotlin/Java)
ls -la | grep -E "build.gradle|settings.gradle|AndroidManifest"

# iOS (Swift)
ls -la | grep -E "\.xcodeproj|\.xcworkspace|Package.swift|Podfile"

# JavaScript / Web
cat package.json 2>/dev/null | grep -E "react|next|vue|angular|express"
```

**Platform Detection Table:**

| Platform | Detection | Skill to Use |
|----------|-----------|--------------|
| Android (Kotlin) | `build.gradle.kts` or `settings.gradle.kts` present | `ping-android-orchestration-sdk` |
| iOS (Swift) | `.xcodeproj`, `.xcworkspace`, or `Package.swift` present | `ping-ios-orchestration-sdk` (planned) |
| JavaScript / Web | `package.json` with web framework dependencies | `ping-js-orchestration-sdk` (planned) |

---

## Step 2: Understand Ping Identity

### What is PingOne Advanced Identity Cloud (AIC)?

PingOne AIC is Ping Identity's cloud-hosted identity platform (formerly ForgeRock Identity Cloud).  It provides:

- **Journeys (Trees)** — Visual, node-based authentication flows configured in the AIC console.
- **OAuth 2.0 / OIDC** — Standards-based token issuance and validation
- **User Management** — Directory services for identity storage

### Orchestration SDKs

The Ping Orchestration SDKs are client-side libraries that interact with PingOne AIC. They handle:

- Driving authentication flows (Journeys) step-by-step
- Rendering dynamic UI based on server-sent callbacks
- Managing OAuth 2.0 / OIDC token exchange
- Secure session and token storage

**Available SDKs:**

| SDK | Platform | Repository | Package |
|-----|----------|------------|---------|
| Orchestration Android SDK | Android (Kotlin) | [ping-android-sdk](https://github.com/ForgeRock/ping-android-sdk/) | `com.pingidentity.sdks:journey` |
| Orchestration iOS SDK | iOS (Swift) | [ping-ios-sdk](https://github.com/ForgeRock/ping-ios-sdk/) | `PingJourney` (SPM / CocoaPods) |
| Orchestration JavaScript SDK | Web (JS/TS) | [ping-javascript-sdk](https://github.com/ForgeRock/ping-javascript-sdk/) | `@forgerock/javascript-sdk` |

### Key Terms

See [Concepts Reference](references/concepts.md) for full details.

| Term | Definition |
|------|------------|
| **Journey (Tree)** | A server-side authentication flow composed of nodes, configured in the AIC admin console |
| **Node** | A step in a Journey that performs an action (collect username, verify password, MFA, etc.) |
| **Callback** | Data sent from a Journey node to the client SDK — represents a UI element or action to perform |
| **ContinueNode** | An SDK node type indicating the flow is in progress and has callbacks to handle |
| **SuccessNode** | An SDK node type indicating authentication completed successfully |
| **ErrorNode / FailureNode** | SDK node types indicating something went wrong |
| **Realm** | A logical partition within a PingOne AIC tenant (commonly `alpha` or `bravo`) |
| **Tenant** | Your PingOne AIC environment instance |
| **OIDC Module** | SDK component that handles OAuth 2.0 / OpenID Connect token exchange after authentication |

---

## Step 3: Prerequisites for PingOne AIC

Before using any Ping Orchestration SDK, you need:

1. **A PingOne AIC tenant**
2. **An OAuth 2.0 client** registered in your AIC tenant for your application
3. **A Journey (Tree)** configured in the AIC admin console (e.g., a `Login` journey)
4. **The OIDC discovery endpoint** for your realm:
   ```
   https://<tenant>.forgeblocks.com/am/oauth2/<realm>/.well-known/openid-configuration
   ```

### Required Configuration Values

| Parameter | Description | Example |
|-----------|-------------|---------|
| `serverUrl` | Base URL of your PingOne AIC tenant | `https://your-tenant.forgeblocks.com/am` |
| `realm` | Realm name in the tenant | `alpha` |
| `clientId` | OAuth 2.0 Client ID for your app | `my-android-client` |
| `discoveryEndpoint` | OIDC discovery URL | `https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration` |
| `redirectUri` | OAuth 2.0 redirect URI registered for the client | `org.forgerock.demo:/oauth2redirect` |
| `scopes` | OAuth 2.0 scopes to request | `openid email profile phone` |
| `cookieName` | SSO cookie name for the realm (optional) | `iPlanetDirectoryPro` |

---

## Step 4: Use the Platform-Specific Skill

Based on your platform detection, use the appropriate skill:

### Tier 1 Platforms (Dedicated Skills)

- **`ping-orchestration-android-journey-sdk`** — Android apps with Jetpack Compose + MVVM using the Journey SDK

### Planned Skills

- `ping-orchestration-ios-journey-sdk` — iOS apps (Swift/SwiftUI) using the Journey SDK
- `ping-orchestration-javascript-journey-sdk` — Web apps (React,   Vue, Angular) using the Journey SDK
- `ping-orchestration-android-davinci-sdk` — Android apps using the DaVinci SDK
- `ping-orchestration-ios-davinci-sdk` — iOS apps using the DaVinci SDK
- `ping-orchestration-javascript-davinci-sdk` — Web apps using the DaVinci SDK

### Not sure which SDK to use?

| Scenario | Recommended SDK |
|----------|----------------|
| Native Android app (Kotlin) needing to integrate with Ping's orchestration offerings, such as PingOne DaVinci, AIC, or PingAM | `ping-android-sdk` |
| Native iOS app (Swift/SwiftUI) needing to integrate with Ping's orchestration offerings, such as PingOne DaVinci, AIC, or PingAM  | `ping-ios-sdk` |
| Single-page web app (React, Vue, Angular) needing to integrate with Ping's orchestration offerings, such as PingOne DaVinci, AIC, or PingAM  | `ping-javascript-sdk` |

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Wrong `redirectUri` scheme | The URI scheme in the SDK config must exactly match the `manifestPlaceholders` (Android) or URL scheme (iOS) |
| Missing `openid` scope | Always include `openid` in your scopes — it's required for OIDC token exchange |
| Wrong discovery endpoint | Must end with `/.well-known/openid-configuration` and include the correct realm |
| Hardcoding credentials | Use build config fields or environment files — never commit secrets |
| Client type mismatch | Mobile apps must use a **Public** OAuth 2.0 client (no client secret) |
| Trailing slash on `serverUrl` | The server URL must **not** end with `/` |

---

## Related Skills

### SDK Skills
- `ping-orchestration-android-journey-sdk` — Orchestration Android SDK with PingOne AIC or PingAM journeys

### References
- [Ping Orchestration SDK Documentation](https://docs.pingidentity.com/sdks/latest/sdks/index.html)
- [PingOne AIC Documentation](https://docs.pingidentity.com/)

---

## Reference Documentation

### Key Concepts
- [Platform & Authentication Concepts](references/concepts.md#ping-identity-platform)
- [Key Terms Glossary](references/concepts.md#key-terms)
- [OAuth 2.0 / OIDC Flows](references/concepts.md#oauth-20--oidc-flows)
- [Troubleshooting](references/concepts.md#troubleshooting)
