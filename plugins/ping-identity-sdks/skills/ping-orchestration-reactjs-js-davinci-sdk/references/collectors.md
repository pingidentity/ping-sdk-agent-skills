# Collector Types Reference (JavaScript DaVinci)

Collectors are returned inside a `ContinueNode` during the DaVinci authentication flow.
Access them via `davinciClient.getCollectors()`.

> **DaVinci vs Journey:** DaVinci collectors are plain objects with `category`, `type`, `input`, and `output` properties.
> They are not class instances — use `davinciClient.update(collector)` to get an updater function.

---

## Single Value Collectors

### TextCollector
Collects **text input** (username, email, custom fields).

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'TextCollector'` | Collector type identifier |
| Category | `collector.category` | `'SingleValueCollector'` | Collector category |
| Key | `collector.output.key` | `string` | Field identifier |
| Label | `collector.output.label` | `string` | Display label |
| Value | `collector.input.value` | `string` | Current input value |

```jsx
const updater = davinciClient.update(collector);
updater('johndoe');
```

---

### PasswordCollector
Collects a **password**.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'PasswordCollector'` | Collector type identifier |
| Category | `collector.category` | `'SingleValueCollector'` | Collector category |
| Key | `collector.output.key` | `string` | Field identifier |
| Label | `collector.output.label` | `string` | Display label |

```jsx
const updater = davinciClient.update(collector);
updater('s3cr3t');
```

> **Note:** PasswordCollector does not expose `input.value` — it does not echo back the password.

---

### SingleSelectCollector
Allows the user to select **one option** from a list.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'SingleSelectCollector'` | Collector type identifier |
| Options | `collector.output.options` | `[{ label, value }]` | Available options |
| Value | `collector.input.value` | `string` | Selected option value |

```jsx
const updater = davinciClient.update(collector);
updater(selectedOption.value);
```

---

## Validated Collectors

### ValidatedTextCollector
Text input **with validation rules**.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'TextCollector'` | Collector type identifier |
| Category | `collector.category` | `'ValidatedSingleValueCollector'` | Collector category |
| Validation | `collector.input.validation` | `ValidationRule[]` | Array of validation rules |

```jsx
const updater = davinciClient.update(collector);
const validator = davinciClient.validate(collector);

updater('user input');
const errors = validator('user input');  // Returns string[] of error messages
```

---

## Action Collectors

### SubmitCollector
Renders a **form submission button**.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'SubmitCollector'` | Collector type identifier |
| Category | `collector.category` | `'ActionCollector'` | Collector category |
| Label | `collector.output.label` | `string` | Button label |

```jsx
<button onClick={() => davinciClient.next()}>
    {collector.output.label}
</button>
```

---

### FlowCollector
Renders a **flow navigation button or link**.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'FlowCollector'` | Collector type identifier |
| Category | `collector.category` | `'ActionCollector'` | Collector category |
| Label | `collector.output.label` | `string` | Button/link label |
| Key | `collector.output.key` | `string` | Flow action key |

```jsx
const startFlow = davinciClient.flow({ action: collector.output.key });
<button onClick={async () => { await startFlow(); renderForm(); }}>
    {collector.output.label}
</button>
```

---

### IdpCollector
Handles **social/external identity provider** login.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'IdpCollector'` | Collector type identifier |
| Label | `collector.output.label` | `string` | Button label (e.g., "Sign in with Google") |
| URL | `collector.output.url` | `string` | IdP authentication URL |

```jsx
<a href={collector.output.url}>
    {collector.output.label}
</a>
```

---

## Multi-Value Collectors

### MultiSelectCollector
Allows the user to select **multiple options**.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'MultiSelectCollector'` | Collector type identifier |
| Options | `collector.output.options` | `[{ label, value }]` | Available options |
| Value | `collector.input.value` | `string[]` | Selected values |

```jsx
const updater = davinciClient.update(collector);
updater(['option1', 'option2']);
```

---

## Object Value Collectors

### DeviceRegistrationCollector
Handles **MFA device registration**.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'DeviceRegistrationCollector'` | Collector type identifier |
| Options | `collector.output.options` | `Device[]` | Available devices |
| Value | `collector.input.value` | `string` | Selected device ID |

---

### DeviceAuthenticationCollector
Handles **MFA device authentication**.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'DeviceAuthenticationCollector'` | Collector type identifier |
| Options | `collector.output.options` | `Device[]` | Available devices |
| Value | `collector.input.value` | `object` | Selected device object |

---

### PhoneNumberCollector
Collects a **phone number**.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'PhoneNumberCollector'` | Collector type identifier |
| Value | `collector.input.value` | `object` | Phone number object |

---

## No-Value / Read-Only Collectors

### ReadOnlyCollector
Displays **static text** (no user input).

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'ReadOnlyCollector'` | Collector type identifier |
| Label | `collector.output.label` | `string` | Text to display |

```jsx
<p>{collector.output.label}</p>
```

---

## Auto-Advancing Collectors

### ProtectCollector
Collects **PingOne Protect risk signals** automatically.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'ProtectCollector'` | Collector type identifier |
| Category | `collector.category` | `'SingleValueAutoCollector'` | Auto-collector category |

```jsx
// Auto-collect signals using @forgerock/protect
import { protect } from '@forgerock/protect';
const signals = await protect.collectSignals();
const updater = davinciClient.update(collector);
updater(signals);
```

---

### FidoRegistrationCollector
Handles **FIDO2 passkey / security-key registration** via the WebAuthn API.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'FidoRegistrationCollector'` | Collector type identifier |
| Category | `collector.category` | `'ObjectValueAutoCollector'` | Auto-collector category |
| Config | `collector.output.config` | `object` | Contains `publicKeyCredentialCreationOptions`, `action`, `trigger` |

```jsx
import { fido } from '@forgerock/davinci-client';

const fidoApi = fido();
const options = collector.output.config.publicKeyCredentialCreationOptions;
const result = await fidoApi.register(options);

if ('error' in result) {
  // Handle error
} else {
  const updater = davinciClient.update(collector);
  updater(result);
}
```

---

### FidoAuthenticationCollector
Handles **FIDO2 passkey / security-key authentication** via the WebAuthn API.

| Property | Path | Type | Description |
|----------|------|------|-------------|
| Type | `collector.type` | `'FidoAuthenticationCollector'` | Collector type identifier |
| Category | `collector.category` | `'ObjectValueAutoCollector'` | Auto-collector category |
| Config | `collector.output.config` | `object` | Contains `publicKeyCredentialRequestOptions`, `action`, `trigger` |

```jsx
import { fido } from '@forgerock/davinci-client';

const fidoApi = fido();
const options = collector.output.config.publicKeyCredentialRequestOptions;
const result = await fidoApi.authenticate(options);

if ('error' in result) {
  // Handle error
} else {
  const updater = davinciClient.update(collector);
  updater(result);
}
```
