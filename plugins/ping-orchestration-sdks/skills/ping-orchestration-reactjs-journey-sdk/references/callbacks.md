# Callback Types Reference

Callbacks are returned inside a Journey `Step` during the authentication flow.
Access them via `step.callbacks` or `step.getCallbacksOfType(callbackType.X)`.

Each callback provides **getter** methods to read display values and **setter** methods to write user input. The SDK sends these values when you call `client.next(step)`.

---

## Core Journey Callbacks

### NameCallback

Collects a **username** or generic name input.

| Method | Returns | Description |
|--------|---------|-------------|
| `getPrompt()` | `string` | Label to display to the user |
| `getInputValue()` | `string` | Current input value |
| `getName()` | `string` | Input field name |
| `setName(value)` | `void` | Set the user's input |
| `setInputValue(value)` | `void` | Alternative setter |

```jsx
function setValue(event) {
  callback.setName(event.target.value);
}
```

---

### PasswordCallback

Collects a **password** or one-time passcode.

| Method | Returns | Description |
|--------|---------|-------------|
| `getPrompt()` | `string` | Label to display |
| `setPassword(value)` | `void` | Set the password value |

```jsx
function setValue(event) {
  callback.setPassword(event.target.value);
}
```

---

### ValidatedCreateUsernameCallback

Collects a username **with server-side policy validation** (used during registration).

| Method | Returns | Description |
|--------|---------|-------------|
| `getPrompt()` | `string` | Label |
| `getInputValue()` | `string` | Current value |
| `getName()` | `string` | Attribute name (e.g., `userName`) |
| `getFailedPolicies()` | `array` | Validation failures from the server |
| `getPolicies()` | `object` | Validation policy definitions |
| `isRequired()` | `boolean` | Whether the field is required |
| `setInputValue(value)` | `void` | Set the username |

**Failed policy handling:**

```jsx
const failedPolicies = callback.getFailedPolicies();
if (failedPolicies?.length) {
  failedPolicies.forEach((failure) => {
    switch (failure.policyRequirement) {
      case 'VALID_USERNAME':
        // "Please choose a different username"
        break;
      case 'VALID_EMAIL_ADDRESS_FORMAT':
        // "Please use a valid email address"
        break;
    }
  });
}
```

---

### ValidatedCreatePasswordCallback

Collects a password **with server-side policy validation** (used during registration).

| Method | Returns | Description |
|--------|---------|-------------|
| `getPrompt()` | `string` | Label |
| `getFailedPolicies()` | `array` | Validation failures (JSON strings) |
| `getPolicies()` | `object` | Validation policy definitions |
| `isRequired()` | `boolean` | Whether the field is required |
| `setPassword(value)` | `void` | Set the password |

**Failed policy handling:**

```jsx
const failedPolicies = callback.getFailedPolicies();
if (failedPolicies?.length) {
  failedPolicies.forEach((curr) => {
    const failureObj = JSON.parse(curr);
    switch (failureObj.policyRequirement) {
      case 'LENGTH_BASED':
        // `Ensure password has at least ${failureObj.params['min-password-length']} characters`
        break;
      case 'CHARACTER_SET':
        // "Ensure password contains 1 capital letter, number, and special character"
        break;
    }
  });
}
```

---

### TextOutputCallback

Displays a **server-provided message** (no user input required).

| Method | Returns | Description |
|--------|---------|-------------|
| `getMessage()` | `string` | The text to display |
| `getMessageType()` | `number` | `0` = INFO, `1` = WARNING, `2` = ERROR, `4` = SCRIPT |

```jsx
export default function TextOutput({ callback }) {
  const message = callback.getMessage();
  return <p>{message}</p>;
}
```

---

### ChoiceCallback

Allows the user to select **one option from a list**.

| Method | Returns | Description |
|--------|---------|-------------|
| `getPrompt()` | `string` | Label |
| `getChoices()` | `string[]` | Available options |
| `getDefaultChoice()` | `number` | Index of default selection |
| `setChoiceIndex(index)` | `void` | Set the selected choice by index |

```jsx
function setValue(event) {
  callback.setChoiceIndex(event.target.value);
}

const choices = callback.getChoices();
// Render as <select> with <option> for each choice
```

---

### ConfirmationCallback

Displays **action options** (e.g., "Submit", "Cancel").

| Method | Returns | Description |
|--------|---------|-------------|
| `getOptions()` | `string[]` | Option labels |
| `setOptionValue(value)` | `void` | Set the selected option |

```jsx
const options = callback.getOptions();
function setOptionValue(event) {
  callback.setOptionValue(event.target.value);
}
// Render as a <select> or button group
```

---

### BooleanAttributeInputCallback

Collects a **true/false** value (e.g., "Receive marketing emails?").

| Method | Returns | Description |
|--------|---------|-------------|
| `getPrompt()` | `string` | Label |
| `getInputValue()` | `boolean` | Current value |
| `setInputValue(value)` | `void` | Set the boolean value |

```jsx
function setValue(event) {
  callback.setInputValue(event.target.checked);
}
// Render as a checkbox
```

---

### StringAttributeInputCallback

Collects an **arbitrary string attribute** (e.g., email, phone, first name).

| Method | Returns | Description |
|--------|---------|-------------|
| `getPrompt()` | `string` | Label |
| `getInputValue()` | `string` | Current value |
| `getName()` | `string` | Attribute name (e.g., `mail`, `givenName`) |
| `getFailedPolicies()` | `array` | Validation failures |
| `getPolicies()` | `object` | Validation policy definitions |
| `isRequired()` | `boolean` | Whether the field is required |
| `setInputValue(value)` | `void` | Set the value |

> Use `getName()` to determine the input type (e.g., `mail` → `type="email"`).

---

### KbaCreateCallback

Collects **Knowledge-Based Authentication** (security question & answer).

| Method | Returns | Description |
|--------|---------|-------------|
| `getPrompt()` | `string` | Instruction text |
| `getPredefinedQuestions()` | `string[]` | Questions to choose from |
| `setQuestion(value)` | `void` | Set the selected question |
| `setAnswer(value)` | `void` | Set the user's answer |

```jsx
const questions = callback.getPredefinedQuestions();
callback.setQuestion(selectedQuestion);
callback.setAnswer(answer);
```

---

### TermsAndConditionsCallback

Displays **terms & conditions** for user acceptance.

| Method | Returns | Description |
|--------|---------|-------------|
| `getTerms()` | `string` | The T&C text |
| `setAccepted(value)` | `void` | Set whether user accepted |

```jsx
const terms = callback.getTerms();
function setValue(event) {
  callback.setAccepted(event.target.checked);
}
// Render as a checkbox with the terms text
```

---

### SelectIdPCallback

Allows the user to select an **external Identity Provider** (Google, Facebook, Apple, etc.).

| Method | Returns | Description |
|--------|---------|-------------|
| `getProviders()` | `array` | Available identity providers |
| `setProvider(providerId)` | `void` | Set the selected provider |

Each provider object contains:
- `provider` — Provider ID
- `uiConfig` — Display configuration (button text, icon, etc.)

---

### RedirectCallback

Instructs the client to **redirect the browser** to an external URL (e.g., social login, SAML).

> This callback is not rendered as a form element. Instead, call `client.redirect(step)` to initiate the browser redirect. After the external flow completes, the browser returns to your app, and you call `client.resume(url)` to continue the Journey.

---

### TextInputCallback

Collects generic **text input** (e.g., OTP, custom field, one-time code).

| Method | Returns | Description |
|--------|---------|-------------|
| `getPrompt()` | `string` | Label |
| `getInputValue()` | `string` | Current/default value |
| `setInputValue(value)` | `void` | Set the value |

```jsx
function setValue(event) {
  callback.setInputValue(event.target.value);
}
```

---

### NumberAttributeInputCallback

Collects a **numeric** value.

| Method | Returns | Description |
|--------|---------|-------------|
| `getPrompt()` | `string` | Label |
| `getInputValue()` | `number` | Current value |
| `getName()` | `string` | Attribute name |
| `setInputValue(value)` | `void` | Set the numeric value |

---

### PollingWaitCallback

Instructs the client to **wait** for a specified duration, then auto-resubmit.

| Method | Returns | Description |
|--------|---------|-------------|
| `getOutputByName('waitTime')` | `number` | Milliseconds to wait |
| `getOutputByName('message')` | `string` | Message to display while waiting |

> This callback auto-submits. Use `setTimeout` or `useEffect` to delay, then call your submit handler.

---

### SuspendedTextOutputCallback

Pauses authentication for **magic link / email verification**. Extends `TextOutputCallback`.

| Method | Returns | Description |
|--------|---------|-------------|
| `getMessage()` | `string` | The message to display |
| `getMessageType()` | `string` | Message type indicator |

> The journey is suspended server-side. Display the message and instruct the user to check their email.

---

### DeviceProfileCallback

**Auto-collecting** — collects device metadata (browser, hardware, platform) and submits automatically.

| Method | Returns | Description |
|--------|---------|-------------|
| `getInputValue()` | `string` | Current collected data |
| `setInputValue(data)` | `void` | Set the device profile JSON |

> Collect data from browser APIs (`navigator`, `screen`, `Intl`) and set as JSON string.

---

### HiddenValueCallback

Carries **hidden data** between client and server. Not rendered visually.

| Method | Returns | Description |
|--------|---------|-------------|
| `getInputValue()` | `unknown` | Current hidden value |
| `setInputValue(value)` | `void` | Set the hidden value |

> Typically handled automatically by the SDK. Include a non-rendering component for completeness.

---

### MetadataCallback

Carries **server-provided metadata** to the client. Not rendered visually.

| Method | Returns | Description |
|--------|---------|-------------|
| `getData()` | `object` | The metadata object from the server |

> Used internally by the SDK (e.g., for WebAuthn). Include a non-rendering component for completeness.

---

### ReCaptchaCallback

Google reCAPTCHA **v2** widget integration.

| Method | Returns | Description |
|--------|---------|-------------|
| `getOutputByName('recaptchaSiteKey')` | `string` | reCAPTCHA site key |
| `setInputValue(token)` | `void` | Set the reCAPTCHA response token |

> Load the reCAPTCHA script, render the widget, and set the response token on the callback.

---

### ReCaptchaEnterpriseCallback

Google reCAPTCHA **Enterprise** integration.

| Method | Returns | Description |
|--------|---------|-------------|
| `getOutputByName('recaptchaSiteKey')` | `string` | reCAPTCHA Enterprise site key |
| `getOutputByName('captchaApiUri')` | `string` | reCAPTCHA Enterprise script URL |
| `setInputValue(token)` | `void` | Set the reCAPTCHA Enterprise response token |

> Load the Enterprise script, execute with the site key, and set the token on the callback.

---

## WebAuthn Callbacks

WebAuthn (FIDO2/Passkey) steps are handled using the SDK's `WebAuthn` utility:

```javascript
import { WebAuthn, WebAuthnStepType } from '@forgerock/journey-client/webauthn';

const webAuthnType = WebAuthn.getWebAuthnStepType(step);

switch (webAuthnType) {
  case WebAuthnStepType.Registration:
    step = await WebAuthn.register(step);
    break;
  case WebAuthnStepType.Authentication:
    step = await WebAuthn.authenticate(step);
    break;
  case WebAuthnStepType.None:
    // Not a WebAuthn step
    break;
}
```

---

## Optional Module Callbacks

### PingOneProtectInitializeCallback / PingOneProtectEvaluationCallback

**Package:** `@forgerock/protect`

PingOne Protect fraud signal collection and risk evaluation.

```javascript
import { protect } from '@forgerock/protect';

// Initialize (typically at app bootstrap or when the callback is received)
const protectApi = await protect({ envId: '<pingone-environment-id>' });
await protectApi.start();

// Evaluate (when PingOneProtectEvaluationCallback is received)
const signals = await protectApi.getData();
callback.setClientError(''); // Clear any previous errors
callback.setSignals(signals);
```

---

## Callback Component Pattern

All callback components in the ReactJS sample follow this pattern:

```jsx
export default function MyCallbackComponent({ callback, inputName }) {
  // 1. GET display values
  const label = callback.getPrompt();
  const currentValue = callback.getInputValue();

  // 2. SET user input
  function setValue(event) {
    callback.setInputValue(event.target.value);
  }

  // 3. RENDER form element
  return (
    <div>
      <label htmlFor={inputName}>{label}</label>
      <input
        id={inputName}
        defaultValue={currentValue}
        onChange={setValue}
        placeholder={label}
      />
    </div>
  );
}
```
