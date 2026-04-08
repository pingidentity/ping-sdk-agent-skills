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

| Platform | Detection | Journey Skill | DaVinci Skill |
|----------|-----------|---------------|---------------|
| Android (Kotlin) | `build.gradle.kts` or `settings.gradle.kts` present | `ping-orchestration-android-journey-sdk` | `ping-orchestration-android-davinci-sdk` |
| iOS (Swift) | `.xcodeproj`, `.xcworkspace`, or `Package.swift` present | `ping-orchestration-ios-journey-sdk` | `ping-orchestration-ios-davinci-sdk` |
| JavaScript / Web | `package.json` with web framework dependencies | `ping-orchestration-reactjs-js-journey-sdk` | `ping-orchestration-reactjs-js-davinci-sdk` |

---

## Step 2: Understand Ping Identity

### What is PingOne Advanced Identity Cloud (AIC)?

PingOne AIC is Ping Identity's cloud-hosted identity platform (formerly ForgeRock Identity Cloud).  It provides:

- **Journeys (Trees)** — Visual, node-based authentication flows configured in the AIC console.
- **OAuth 2.0 / OIDC** — Standards-based token issuance and validation
- **User Management** — Directory services for identity storage

### What is PingOne DaVinci?

PingOne DaVinci is Ping Identity's cloud-based visual identity orchestration engine. It provides:

- **Flows** — Visual, drag-and-drop authentication and identity workflows
- **Connectors** — Pre-built integrations with PingOne services, third-party IdPs, and custom APIs
- **Collectors** — UI components (text fields, buttons, dropdowns) sent to the client SDK for dynamic rendering

> **Journey vs DaVinci:** Journeys use PingOne AIC / PingAM with *callbacks*. DaVinci uses PingOne with *collectors*. The SDKs are platform-specific but the orchestration server differs.

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
| DaVinci Android SDK | Android (Kotlin) | [ping-android-sdk](https://github.com/ForgeRock/ping-android-sdk/) | `com.pingidentity.sdks:davinci` |
| DaVinci iOS SDK | iOS (Swift) | [ping-ios-sdk](https://github.com/ForgeRock/ping-ios-sdk/) | `PingDavinci` (SPM) |
| DaVinci JavaScript SDK | Web (JS/TS) | [ping-javascript-sdk](https://github.com/ForgeRock/ping-javascript-sdk/) | `@forgerock/davinci-client` |

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
| **DaVinci Flow** | A server-side orchestration flow built in the PingOne DaVinci visual editor |
| **Connector** | A DaVinci node representing a step in the flow — contains collectors to render |
| **Collector** | Data sent from a DaVinci connector to the client SDK — represents a UI element (text field, button, etc.) |

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

Based on your platform detection **and** your orchestration server, use the appropriate skill:

### Journey Skills (PingOne AIC / PingAM)

- **`ping-orchestration-android-journey-sdk`** — Android apps with Jetpack Compose + MVVM using the Journey SDK
- **`ping-orchestration-ios-journey-sdk`** — iOS apps with SwiftUI + MVVM using the Journey SDK
- **`ping-orchestration-reactjs-js-journey-sdk`** — ReactJS SPAs with Vite + React 18 using the Journey JavaScript SDK

### DaVinci Skills (PingOne DaVinci)

- **`ping-orchestration-android-davinci-sdk`** — Android apps with Jetpack Compose + MVVM using the DaVinci SDK
- **`ping-orchestration-ios-davinci-sdk`** — iOS apps with SwiftUI + MVVM using the DaVinci SDK
- **`ping-orchestration-reactjs-js-davinci-sdk`** — ReactJS SPAs with Vite + React 18 using the DaVinci JavaScript SDK

### Not sure which orchestration server?

| Question | Journey (AIC/PingAM) | DaVinci (PingOne) |
|----------|---------------------|-------------------|
| Where do you build flows? | PingOne AIC or PingAM admin console ("Trees") | PingOne DaVinci visual editor |
| What is the server URL format? | `https://<tenant>.forgeblocks.com/am` | `https://auth.pingone.com/<env-id>/as` |
| What does the SDK receive? | **Callbacks** (NameCallback, PasswordCallback, etc.) | **Collectors** (TextCollector, PasswordCollector, etc.) |
| SDK entry point? | `Journey` / `journey()` | `DaVinci` / `davinci()` |

### Not sure which platform skill to use?

| Scenario | Recommended Skill |
|----------|------------------|
| Native Android app (Kotlin) + PingOne AIC / PingAM | `ping-orchestration-android-journey-sdk` |
| Native Android app (Kotlin) + PingOne DaVinci | `ping-orchestration-android-davinci-sdk` |
| Native iOS app (Swift/SwiftUI) + PingOne AIC / PingAM | `ping-orchestration-ios-journey-sdk` |
| Native iOS app (Swift/SwiftUI) + PingOne DaVinci | `ping-orchestration-ios-davinci-sdk` |
| Web SPA (React) + PingOne AIC / PingAM | `ping-orchestration-reactjs-js-journey-sdk` |
| Web SPA (React) + PingOne DaVinci | `ping-orchestration-reactjs-js-davinci-sdk` |

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

### Journey SDK Skills (PingOne AIC / PingAM)
- `ping-orchestration-android-journey-sdk` — Android Journey SDK with Jetpack Compose + MVVM
- `ping-orchestration-ios-journey-sdk` — iOS Journey SDK with SwiftUI + MVVM
- `ping-orchestration-reactjs-js-journey-sdk` — ReactJS Journey SDK with Vite + React 18

### DaVinci SDK Skills (PingOne DaVinci)
- `ping-orchestration-android-davinci-sdk` — Android DaVinci SDK with Jetpack Compose + MVVM
- `ping-orchestration-ios-davinci-sdk` — iOS DaVinci SDK with SwiftUI + MVVM
- `ping-orchestration-reactjs-js-davinci-sdk` — ReactJS DaVinci SDK with Vite + React 18

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
