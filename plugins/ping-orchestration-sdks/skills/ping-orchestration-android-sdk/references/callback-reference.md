# Journey Callback Reference

Standard callbacks are in `com.pingidentity.journey.callback`. Non-standard packages marked with `†`.

| Callback | Package† | Read | Write | Suspend method |
|---|---|---|---|---|
| `NameCallback` | — | `prompt` | `callback.name = text` | — |
| `PasswordCallback` | — | `prompt` | `callback.password = text` | — |
| `ValidatedUsernameCallback` | — | `prompt` | `callback.username = text` (**NOT** `.value`) | — |
| `ValidatedPasswordCallback` | — | `prompt` | `callback.password = text` (**NOT** `.value`) | — |
| `TextInputCallback` | — | `prompt` | `callback.text = text` (**NOT** `.value`) | — |
| `TextOutputCallback` | — | `message`, `messageType` | display only | — |
| `ChoiceCallback` | — | `prompt`, `choices: List<String>` | `callback.selectedIndex = index` (**NOT** `.selected`) | — |
| `ConfirmationCallback` | — | `prompt`, `options: List<String>` | `callback.selectedIndex = index` | — |
| `TermsAndConditionsCallback` | — | `terms` | `callback.accepted = true` (**NOT** `.accept`) | — |
| `KbaCreateCallback` | — | `predefinedQuestions` | `callback.selectedQuestion = q; callback.selectedAnswer = a` | — |
| `BooleanAttributeInputCallback` | — | `prompt` | `callback.value = bool` | — |
| `StringAttributeInputCallback` | — | `prompt` | `callback.value = text` | — |
| `DeviceProfileCallback` | `com.pingidentity.device.profile` | — | — | `callback.collect()` (**NOT** `.execute()`) |
| `DeviceBindingCallback` | `com.pingidentity.device.binding.journey` | — | — | `callback.bind()` (**NOT** `.execute()`) |
| `FidoRegistrationCallback` | `com.pingidentity.fido.journey` | — | — | `callback.register()` |
| `FidoAuthenticationCallback` | `com.pingidentity.fido.journey` | — | — | `callback.authenticate()` |
| `PingOneProtectInitializeCallback` | `com.pingidentity.protect.journey` | — | — | `callback.start()` (**NOT** `.initialize()`) |
| `PingOneProtectEvaluationCallback` | `com.pingidentity.protect.journey` | — | — | `callback.collect()` (**NOT** `.evaluate()`) |
| `SelectIdpCallback` | `com.pingidentity.idp.journey` | `providers: List<IdPValue>` | `callback.value = idp.provider` (**NOT** `.setSelectedIdp()`) | — |
| `SelectIdpCallback.IdPValue` | — | `provider: String`, `uiConfig` | — (display name = `idp.provider`, **NOT** `idp.type`) | — |

**Auto-advancing callbacks** — wrap in `LaunchedEffect(callback)`, set `showNext = false`:
`PollingWaitCallback`, `DeviceProfileCallback`, `DeviceBindingCallback`, `DeviceSigningVerifierCallback`, `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`, `ReCaptchaEnterpriseCallback`.

**Gradle modules for non-standard callbacks:**

| Module | Callbacks |
|---|---|
| `device-profile` | `DeviceProfileCallback` |
| `binding` | `DeviceBindingCallback`, `DeviceSigningVerifierCallback` |
| `fido` | `FidoRegistrationCallback`, `FidoAuthenticationCallback` |
| `protect` | `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback` |
| `external-idp` | `SelectIdpCallback` |
