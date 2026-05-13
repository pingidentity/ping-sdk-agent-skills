---
name: ping-sdk-js
description: >-
  Use when building web apps with the Ping Orchestration JavaScript SDK —
  phrases like "add Ping auth to my web app", "use PingOne in React",
  "set up Journey in JavaScript", "build a Ping login page". Detects
  framework (React active; Angular, Vue, vanilla JS on the roadmap),
  collects shared config, delegates Journey to
  ping-orchestration-reactjs-js-journey-sdk and DaVinci to
  ping-orchestration-reactjs-js-davinci-sdk, handles OIDC centralized
  login inline.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# Ping JavaScript SDK

First point of contact for building web apps with the Ping Orchestration JavaScript SDK (`@forgerock/journey-client`, `@forgerock/davinci-client`, `@forgerock/oidc-client`). Handles three authentication flows:

- **Journey** — callback-based auth against PingAM or PingOne AIC → delegates to `ping-orchestration-reactjs-js-journey-sdk`
- **DaVinci** — collector-based auth against PingOne DaVinci → delegates to `ping-orchestration-reactjs-js-davinci-sdk`
- **OIDC centralized login** — OAuth2 authorization code flow (browser redirect) → handled inline

Runs a three-step wizard (W1 → W2 → W3) to determine flow type, detect framework, collect shared config, then hands off or generates code.
