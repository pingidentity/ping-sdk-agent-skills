# Common Mistakes

| Mistake | Fix |
|---|---|
| `journey.start()` / `.user()` / `.callbacks` / `Logger.STANDARD` unresolved | All are top-level extensions — add explicit imports (see Section 5 import table) |
| Wrong package for advanced callbacks | See `references/callback-reference.md`. e.g. `DeviceBindingCallback` is `com.pingidentity.device.binding.journey`, NOT `com.pingidentity.journey.callback` |
| Wrong property name on callback | See callback table. Common gotchas: `ValidatedUsernameCallback` → `.username`; `TextInputCallback` → `.text`; `ChoiceCallback` → `.selectedIndex`; `TermsAndConditionsCallback` → `.accepted` |
| Wrong suspend method name | `DeviceProfileCallback.collect()`, `DeviceBindingCallback.bind()`, `PingOneProtectInitializeCallback.start()`, `PingOneProtectEvaluationCallback.collect()` |
| `SelectIdpCallback` API wrong | `.providers` (not `.idpList`); `callback.value = idp.provider` (no `.setSelectedIdp()`); display = `idp.provider` (not `idp.type`) |
| `SuccessNode` recomposition loop | Wrap navigation in `LaunchedEffect(Unit)` |
| Auto-advancing callback shows Next button | Set `showNext = false` and wrap in `LaunchedEffect(callback)` |
| `node ==` comparison fails | `Node` has no `equals()` — use `counter: Int` in state |
| HTTP 401 on Ping SDK artifacts | SDK 2.0.0+ is on Maven Central; remove any custom `maven { }` block |
| Wrong MFA artifact IDs | `com.pingidentity.sdks:push` and `:oath` — not `mfa-push`/`mfa-oath` |
| `androidx.browser`/`core` AAR metadata fail | Requires AGP 8.9.1+ and `compileSdk = 36` |
| K2 compiler crash (`FirIncompatibleClassExpressionChecker`) | Kotlin 2.0.x incompatible with AGP 8.9.1 — use `kotlin = "2.1.21"` |
| Missing `gradle.properties` | Add `android.useAndroidX=true` + `android.enableJetifier=true` at project root |
| `menuAnchor()` deprecation | Use `Modifier.menuAnchor(MenuAnchorType.PrimaryNotEditable)` |
| DaVinci vs Journey Oidc import conflict | `com.pingidentity.davinci.module.Oidc` vs `com.pingidentity.journey.module.Oidc` |
| `PingTextField` name clash | Color constant and composable can't share the same name — composable is `PingTextFieldBranded` |
| `PingLoadingOverlay` not covering screen | Uses `fillMaxSize()` — must be top sibling in `Box(Modifier.fillMaxSize())` |
| AAPT error: `style/Theme.Material3.DayNight.NoActionBar` not found | Use `Theme.AppCompat.Light.NoActionBar` as the XML theme parent — Material3 XML theme requires an extra library not in the default dependency set |
| AAPT error: `mipmap/ic_launcher` not found | Scaffolded projects have no mipmap dirs — set `android:icon="@drawable/ping_logo"` and `android:roundIcon="@drawable/ping_logo"` in AndroidManifest.xml |
