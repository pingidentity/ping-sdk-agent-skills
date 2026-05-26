# Common Pitfalls

| Symptom | Likely cause |
|---|---|
| `cannot find type 'Callback' in scope` | Missing `import PingJourneyPlugin` |
| `cannot find type 'Collector' in scope` | Missing `import PingDavinciPlugin` |
| `cannot find type 'ContinueNode' / 'SuccessNode'` | Missing `import PingOrchestrate` |
| `use of protocol 'Callback' as a type must be written 'any Callback'` | Swift 6 existential syntax |
| `cannot use optional chaining on non-optional value of type 'any Error'` | `FailureNode.cause` is non-optional — remove the `?` |
| `'appendInterpolation' is deprecated` on `\(value)` where value is `Any` | Use `String(describing: value)` |
| `result of call to 'signOff()' is unused` | Use `_ = await journey.signOff()` |
| `type 'any Node' cannot conform to 'Equatable'` | Use a Bool flag instead of `.onChange(of: node)` |
| `'Observable()' is only available in iOS 17.0 or newer` | `IPHONEOS_DEPLOYMENT_TARGET = 16.0` in xcconfig — bump to `18.0` |
| `cannot find 'UserDefaults' in scope` inside `@Observable` | Missing `import Foundation` |
| Tokens overwritten between Journey instances | Each needs a unique `account` string on `KeychainStorage<Token>` |
| Social IdP redirect not handled | Missing `onOpenURL` → `OpenURLMonitor.shared.handleOpenURL` |
| Browser opens but redirect never returns | URL scheme not registered — use Ruby snippet in Section 7 / Step D |
| `error: expected to find '=' in macro condition` at xcconfig | Used `INFOPLIST_KEY_CFBundleURLTypes[0]...` syntax — use underscore-numeric form instead |
| `error: Multiple commands produce Info.plist` | Hand-authored `Info.plist` conflicts with `GENERATE_INFOPLIST_FILE = YES` — delete it |
| `authorize()` returns `.failure(.authorizeError)` immediately | `redirectUri` scheme doesn't match registered scheme |
| `ASWebAuthenticationSession` completes but stays on browser | Missing `BrowserLauncher.currentBrowser.handleAppActivation()` on scene-active |
| `cannot find 'OpenURLMonitor' / 'BrowserLauncher' in scope` | Missing `import PingBrowser` |
| `cannot find type 'UITextContentType'` in Theme.swift | Missing `import UIKit` |
| `Unable to find a device matching ... iPhone 16` | Hardcoded simulator name — detect dynamically via `xcrun simctl list devices` (see `assets/project-scaffolding.md` Step G) |
| `Missing package product '<AppName>Feature'` | Cleanup script missed occurrences — run `grep -n <AppName>Feature project.pbxproj` and delete all matches |
| `undefined method 'objects'` in Ruby script | Use `project.objects.each`, not `project.root_object.objects` |
| DaVinci: `actionKey` and `eventType` missing from POST body | `SubmitCollector.value` / `FlowCollector.value` not set before `next()` |
| DaVinci: `ForEach requires Option to conform to Hashable` | Use `ForEach(collector.options.indices, id: \.self)` |
| DaVinci: `PhoneNumberCollector has no member 'value'` | Use `.phoneNumber` not `.value` |
| DaVinci: `ProtectCollector has no member 'start'` | Use `await collector.collect()` not `.start()` |
| DaVinci: `extra argument 'deviceName'` on `FidoRegistrationCollector` | DaVinci variant takes only `window:` — no `deviceName:` |
| DaVinci: `DeviceRegistrationCollector has no member 'register'` | Set `collector.value = device` then call `onNext()` |
| DaVinci: `Device has no member 'name'` | Use `device.title`, not `.name` |
| Journey: `ValidatedUsernameCallback has no member 'value'` | Use `.username` |
| Journey: `ConfirmationCallback has no member 'value'` | Use `.selectedIndex: Int?`; buttons array is `.options` not `.choices` |
| Journey: `TermsAndConditionsCallback has no member 'accept'` | Use `.accepted` |
| Journey: `KbaCreateCallback has no member 'answer'` | Use `.selectedAnswer` |
| Journey: `SelectIdpCallback has no member 'setProvider'` | Assign `.value = provider.provider` directly |
| SPM: `Type checking error: got 'XCSwiftPackageProductDependency' for attribute 'fileRef'` | Use `build_file.product_ref = dep`, not `build_file.file_ref = dep` |
| `FBSOpenApplicationServiceErrorDomain` on test | Simulator in bad state — run `xcrun simctl shutdown all` |
