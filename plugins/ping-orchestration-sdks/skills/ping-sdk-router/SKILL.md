---
name: ping-sdk-router
description: >-
  Use when a user asks for help with Ping Identity SDK integration without
  specifying a platform — phrases like "help me add Ping auth", "I want to use
  PingOne", "get started with the Ping SDK". Probes the project to detect
  Android, iOS, JavaScript, or React Native, asks if ambiguous, and routes to
  the matching umbrella skill (ping-sdk-android, ping-sdk-ios, planned: ping-sdk-js,
  ping-sdk-react-native) or to forgerock-to-ping-journey-migration when ForgeRock
  SDK references are present.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# Ping SDK Router

First point of contact for vague Ping Identity SDK requests. Probes the working directory to detect platform (Android, iOS, JavaScript, React Native) and ForgeRock SDK references, then hands off to the most suitable umbrella skill in this plugin. New platforms are added by editing one row in the platform registry below — the decision tree picks them up automatically.
