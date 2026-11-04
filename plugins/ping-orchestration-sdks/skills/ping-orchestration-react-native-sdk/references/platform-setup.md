# Platform Setup (Android and iOS)

Apply these after the npm install and before running the app. The Ping SDK requires React Native >= 0.80.1. The Baseline section applies to every flow (Journey, OIDC, DaVinci). Every other section applies only when that flow or package is used. Package behavior details live in each package's README in the React Native SDK repository; where this file is silent, defer to the README rather than inventing steps.

## Baseline (all flows)

**iOS**: requires iOS 16.0. Three independent settings; all are required.

**Podfile platform.** In `ios/Podfile` ensure:

```
platform :ios, '16.0'
```

**Pod targets.** CocoaPods builds each pod at the deployment target its podspec declares, not at the `platform` line above (which only gates version resolution). Transitive pods such as GoogleSignIn, AppAuth, GTMSessionFetcher and Promises declare 9.0-12.0, and current Xcode errors on any deployment target below 15.0. React Native 0.80's own `post_install` only floors pod targets at 15.1 and skips resource-bundle targets (the `-Privacy` aggregates), so an explicit raise is required. Inside the `post_install do |installer| ... end` block in `ios/Podfile` — the template's block, after the `react_native_post_install(...)` call; add the block if the Podfile has none — append:

```ruby
installer.pods_project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  end
end
```

Setting 16.0 unconditionally can never lower a pod below its own requirement: a pod whose podspec declared above 16.0 fails `pod install` resolution before the hook runs. Re-run `cd ios && pod install` after changing the block.

**App target.** In `ios/<AppName>.xcodeproj/project.pbxproj`, every `IPHONEOS_DEPLOYMENT_TARGET` must be 16.0 or higher. The Podfile line never changes the app target: CocoaPods does not edit the app project. A fresh React Native 0.80+ template ships four occurrences, all `15.1` (app target Debug and Release, project-level Debug and Release). Inspect before editing:

```bash
grep -n "IPHONEOS_DEPLOYMENT_TARGET" ios/<AppName>.xcodeproj/project.pbxproj
```

If every value is 16.0 or higher, there is nothing to change. If any value is below 16.0, raise those occurrences to 16.0 (never lower a value that is already higher):

```bash
sed -i '' -E 's/IPHONEOS_DEPLOYMENT_TARGET = ([0-9]|1[0-5])(\.[0-9]+)?;/IPHONEOS_DEPLOYMENT_TARGET = 16.0;/g' ios/<AppName>.xcodeproj/project.pbxproj
```

The pattern matches only values below 16 (single digits and 10 through 15), so a future template default of 16.x or newer is left untouched. If the grep shows a shape the sed does not cover (quoted values, targets that inherit from an `.xcconfig`), edit those occurrences individually instead. Re-run the grep afterwards to confirm no value below 16.0 remains.

An app target below 16.0 compiles the pods fine but fails on app-target Swift that imports them ("`X` is only available in iOS 16.0 or newer", for example the Social login AppDelegate routing and native push bridging), and on an iOS 15 device the app crashes at launch because the pod frameworks are built for a 16.0 minimum.

**Android**: requires minSdk 29. In `android/build.gradle` ensure:

```
minSdkVersion = 29
```

**Android JVM target.** The Ping SDK Android modules compile with JVM target 21. React Native's Gradle plugin aligns every module to Java 17, which makes `:ping-identity_rn-core:compileDebugKotlin` fail with "Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks" (Java 17 vs Kotlin 21). Disable the alignment in `android/gradle.properties`:

```
react.internal.disableJavaVersionAlignment=true
```

This flag is global: third-party modules that relied on the alignment to mask their own internal Java/Kotlin split (for example `react-native-safe-area-context`, Java 11 vs Kotlin 21) now fail the same check. Downgrade the JVM-target mismatch to a warning in the same file (the same setup `PingSampleApp` in the React Native SDK repository uses):

```
kotlin.jvm.target.validation.mode=warning
```

**Pods.** Run after installing packages, and again after any change to the `Podfile`:

```bash
cd <projectDir>/ios && pod install
```

## OIDC flow (`rn-oidc`)

**Android.** `rn-oidc` injects `${appRedirectUriScheme}` into its `AndroidManifest.xml`. Add a placeholder in `android/app/build.gradle` inside `defaultConfig`:

```groovy
manifestPlaceholders = [appRedirectUriScheme: "<redirectUri-scheme>"]
```

where `<redirectUri-scheme>` is the scheme portion of your `redirectUri` (e.g. `com.example.app` for `com.example.app://oauth2redirect`). Without this the build fails with "no value for &lt;appRedirectUriScheme&gt; is provided".

Do **not** add the `CustomTabActivity` intent filter to the app manifest: the library declares it with the scheme-bound intent filter, and it merges in automatically. Adding a second filter in the app makes the app intercept the redirect before the token exchange completes.

**iOS.** Register the redirect URI scheme in `ios/<AppName>/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string><redirectUri-scheme></string>
    </array>
  </dict>
</array>
```

A plain DaVinci flow needs none of this. DaVinci needs redirect wiring only for the Social Login integration (see `rn-external-idp` below).

## FIDO passkeys (`rn-fido`)

Apply the app setup below. The server-side items at the end are prerequisites the user completes outside the app — hosting files and configuring the RP server is outside of the scope of this setup.

**Android app setup**
- On Android API 33 and older, add `androidx.credentials:credentials-play-services-auth`.
- For non-discoverable credentials or legacy security keys, add `com.google.android.gms:play-services-fido`.
- FIDO calls require a foreground `Activity`.

**iOS app setup** (required — passkeys will silently fail without these)

1. Add `NSFaceIDUsageDescription` to `ios/<AppName>/Info.plist`:
   ```xml
   <key>NSFaceIDUsageDescription</key>
   <string>Used to authenticate with a passkey</string>
   ```

2. Add an Associated Domains entitlement for `webcredentials` in `ios/<AppName>/<AppName>.entitlements` (create the file if it does not exist, then link it in Xcode under Signing & Capabilities → Associated Domains):
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
     <key>com.apple.developer.associated-domains</key>
     <array>
       <string>webcredentials:yourdomain.com</string>
     </array>
   </dict>
   </plist>
   ```
   Replace `yourdomain.com` with the domain configured in the PingAM/AIC FIDO service.

- FIDO calls require an active `UIWindowScene` / `ASPresentationAnchor`.

**Server-side (tell the user to complete; not agent work)**
- Your server must host Digital Asset Links at `https://<rp-domain>/.well-known/assetlinks.json`, containing the app's Android package name and signing certificate fingerprint(s).
- Your server must host the Apple App Site Association file at `https://<rp-domain>/.well-known/apple-app-site-association`, with the `webcredentials` section pointing to the app's Team ID + Bundle ID.
- The Android origin domains for FIDO must be configured on the relying party (RP) server; without them the passkey flow can still fail even when Digital Asset Links are correct. This setting is not covered in these docs: tell the user to confirm it with whoever administers the RP/server, and do not invent a console path.

## Social login (`rn-external-idp`)

Applies to Journey `SelectIdpCallback` and to the DaVinci `SOCIAL_LOGIN_BUTTON` collector.

**Android**
- Register the redirect scheme in `android/app/build.gradle`:

  ```groovy
  android {
      defaultConfig {
          manifestPlaceholders["appRedirectUriScheme"] = "myapp"
      }
  }
  ```

  Replace `myapp` with your registered custom scheme (e.g. `com.example.myapp`). This is required for devices that do not support Auth Tabs and fall back to Custom Tabs.
- To enable native Google or Facebook login (no browser redirect), add the provider SDKs to `android/app/build.gradle`:

  ```groovy
  dependencies {
      // Google Sign-In
      implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")
      // Required for devices running Android 13 and below
      implementation("androidx.credentials:credentials-play-services-auth:1.5.0")

      // Facebook Login
      implementation("com.facebook.android:facebook-login:18.0.3")
  }
  ```

**iOS**
- Add the custom URL scheme under `CFBundleURLTypes` in `ios/<AppName>/Info.plist` (same shape as the OIDC snippet above), using the scheme registered in your server configuration.
- Native provider handlers are detected at runtime. Add the provider pods you need to the `Podfile`, then run `pod install` again:

  ```ruby
  pod 'PingExternalIdPGoogle'
  pod 'PingExternalIdPFacebook'
  pod 'PingExternalIdPApple'
  ```

  With a provider pod absent, Journey `authorizeForJourney` rejects with `EXTERNAL_IDP_UNSUPPORTED_PROVIDER`, and DaVinci falls back to browser sign-in.
- Google and Facebook only: route incoming callback URLs to the linked handlers. Apple Sign-In does not need this. Which lifecycle method receives the callback depends on the app's iOS lifecycle; detect it before writing any code:

  ```bash
  plutil -convert xml1 -o - "ios/<AppName>/Info.plist" | grep -q UISceneDelegateClassName && echo "scene-based" || echo "app-delegate"
  ```

  **App-delegate lifecycle** (no scene manifest: the React Native 0.77-0.87 templates, Expo prebuild without scenes): add the routing to `ios/<AppName>/AppDelegate.swift`, creating `application(_:open:options:)` if it does not exist:

  ```swift
  #if canImport(PingExternalIdPFacebook)
  import PingExternalIdPFacebook
  #endif
  #if canImport(PingExternalIdPGoogle)
  import PingExternalIdPGoogle
  #endif

  func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    var handled = false
  #if canImport(PingExternalIdPFacebook)
    handled = FacebookHandler.handleOpenURL(application, url: url, options: options)
  #endif
  #if canImport(PingExternalIdPGoogle)
    handled = GoogleHandler.handleOpenURL(application, url: url, options: options) || handled
  #endif
    return handled
  }
  ```

  **Scene-based lifecycle** (`UIApplicationSceneManifest` with `UISceneDelegateClassName`: the React Native 0.88+ template with a `SceneDelegate.swift`; 0.77-0.87 templates are AppDelegate-only): iOS never calls `application(_:open:options:)` in a scene-based app, so the AppDelegate snippet above is dead code there and Google/Facebook login silently does nothing. Route in the scene delegate class named by `UISceneDelegateClassName` (the template's `SceneDelegate.swift`). That class already implements both methods below, forwarding URLs to `RCTLinkingManager`: keep the forwarding as the fallback for URLs the handlers do not claim, so React's `Linking` API keeps working. Warm opens arrive at `scene(_:openURLContexts:)`; cold starts (the URL launches the app) arrive in `connectionOptions.urlContexts` of `scene(_:willConnectTo:options:)`, so both are required.

  Replace the existing `scene(_:openURLContexts:)` body (template forwarding only) with:

  ```swift
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    var handled = false
  #if canImport(PingExternalIdPFacebook)
    for context in URLContexts {
      handled = FacebookHandler.handleOpenURL(UIApplication.shared, url: context.url, options: [:]) || handled
    }
  #endif
  #if canImport(PingExternalIdPGoogle)
    for context in URLContexts {
      handled = GoogleHandler.handleOpenURL(UIApplication.shared, url: context.url, options: [:]) || handled
    }
  #endif
    if !handled {
      RCTLinkingManager.scene(scene, openURLContexts: URLContexts)
    }
  }
  ```

  Inside the existing `scene(_:willConnectTo:options:)`, after the `startReactNative(...)` call, add the same calls for cold-start URLs:

  ```swift
  #if canImport(PingExternalIdPFacebook)
  for context in connectionOptions.urlContexts {
    _ = FacebookHandler.handleOpenURL(UIApplication.shared, url: context.url, options: [:])
  }
  #endif
  #if canImport(PingExternalIdPGoogle)
  for context in connectionOptions.urlContexts {
    _ = GoogleHandler.handleOpenURL(UIApplication.shared, url: context.url, options: [:])
  }
  #endif
  ```

  The `#if canImport` guards and imports are identical to the AppDelegate variant. Merge into methods the class already has; do not declare a second copy of either method.

**Provider consoles.** Google Cloud OAuth client IDs (Web, Android, iOS, with `GIDClientID` and the reversed client ID URL scheme in `Info.plist`) and the Facebook and Apple equivalents are configured outside the app. The exact steps are in the `rn-external-idp` README ("Provider console setup"); do not paraphrase beyond it.

## PingOne Protect (`rn-protect`)

iOS needs `cd ios && pod install` after installing the package. There is no other native configuration. Collection runs in the background and needs no foreground Activity or window.

## Device profile (`rn-device-profile`)

**Android.** Add the permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Required for the network collector -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Optional: only for the location collector (prompts the user automatically) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

If you use the `location` collector, also add Google Play Services Location at the app level (the module rejects location collection at runtime when it is missing):

```groovy
dependencies {
  implementation "com.google.android.gms:play-services-location:21.3.0"
}
```

Keep the version consistent with the rest of the app's Play Services dependencies, and rebuild after changing Gradle dependencies.

**iOS.** If you use the `location` collector, add a usage description to `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses your location to complete device profiling.</string>

<!-- Optional: only for background location access -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app uses your location to complete device profiling.</string>
```

## Device binding and signing (`rn-binding`, `rn-device-client`)

- Android requires a foreground `Activity` for binding and signing calls.
- iOS requires an active `UIWindowScene` / `ASPresentationAnchor` for binding and signing calls.
- `rn-device-client` minimums are the same as the Baseline: iOS 16.0, Android minSdk 29.

## Push MFA (`rn-push`)

**Android (FCM).** Add the Firebase peer dependency to the app's `build.gradle`:

```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.0.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

**iOS (APNs).** Enable the Push Notifications capability in Xcode and add the APNs key in the Apple Developer portal.

**Token and message delivery.** The SDK must receive the platform push token and incoming messages from the app's existing push infrastructure. The wiring depends on whether the app uses a React Native JS push library (no native changes) or already has a native push provider (forward tokens and messages with `RNPingPushBridge` from the Android `FirebaseMessagingService` and the iOS `AppDelegate`). Follow the "Native setup" section of the `rn-push` README for the exact snippets; do not reproduce them from memory.
