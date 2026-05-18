# Callback / Collector Tiers

| Tier | Who it's for |
|---|---|
| **Basic** | Login/password journeys with optional multi-choice prompts. Zero extra dependencies. |
| **Standard** | All common patterns — FIDO, Protect, device binding/profile, T&C, KBA, polling wait, consent, social IdP (browser-based). No third-party native social SDKs. |
| **Full fat** | Matches official PingExample sample app. Adds native social login (Apple, Facebook, Google) and ReCaptcha Enterprise. Requires those third-party SDKs. |

**Tier 1 — Basic**

Journey: `NameCallback`, `PasswordCallback`, `TextOutputCallback`, `ChoiceCallback`
DaVinci: `TextCollector`, `PasswordCollector`, `SubmitCollector`, `LabelCollector`, `FlowCollector`

**Tier 2 — Standard**

Everything in Basic plus:

Journey: `TextInputCallback`, `ValidatedUsernameCallback`, `ValidatedPasswordCallback`, attribute callbacks, `ConfirmationCallback`, `SuspendedTextOutputCallback`, `HiddenValueCallback`, `PollingWaitCallback`, `TermsAndConditionsCallback`, `ConsentMappingCallback`, `KbaCreateCallback`, `SelectIdpCallback`, `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `DeviceProfileCallback`, `DeviceBindingCallback`, `DeviceSigningVerifierCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`

DaVinci: `MultiSelectCollector` (CheckBox/ComboBox), `SingleSelectCollector` (Dropdown/RadioButton), `PhoneNumberCollector`, `ProtectCollector`, `FidoRegistrationCollector`, `FidoAuthenticationCollector`, `DeviceRegistrationCollector`, `DeviceAuthenticationCollector`

Additional SPM products: `PingFido`, `PingProtect`, `PingBinding`, `PingDeviceProfile`, `PingExternalIdP`

Self-advancing callbacks (suppress the Next button): `ConfirmationCallback`, `SuspendedTextOutputCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`, `SelectIdpCallback`, `IdpCallback`, `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `DeviceBindingCallback`, `DeviceSigningVerifierCallback`

**Tier 3 — Full fat**

Additional Journey: `IdpCallback`, `ReCaptchaEnterpriseCallback`
Additional DaVinci: `IdpCollector`
Additional SPM: `PingReCaptchaEnterprise`, `PingExternalIdPApple`, `PingExternalIdPFacebook`, `PingExternalIdPGoogle`

**Decision guide:**
```
FIDO / Protect / device binding / T&C / KBA in your journey?
  No  → Basic
  Yes → Native Apple/Google/Facebook social or ReCaptcha?
          No  → Standard
          Yes → Full fat
```
