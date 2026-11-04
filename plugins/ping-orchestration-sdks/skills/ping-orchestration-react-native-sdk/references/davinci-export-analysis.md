# DaVinci Export Analysis

When the user provides a DaVinci flow export JSON (exported from the DaVinci console via **More options > Download Flow JSON**; optionally with subflows included), run this analysis before writing any TypeScript/TSX. The goal is to determine which integration packages the React Native app needs (`rn-external-idp`, `rn-fido`, `rn-protect`), preview the core collectors, and pre-select the collector tier for the wizard. Collector payload shapes and integration run order are specified in [davinci-collectors.md](davinci-collectors.md).

The export contains environment identifiers (company/customer IDs, connection IDs): never echo them back or write them into generated files.

## Export Format

The export comes in one of two shapes. Detect the envelope first (A1); every later step handles both.

**(a) Single flow**: the flow object is at the file root:

```text
graphData: flow graph; nodes at graphData.elements.nodes[].data
connectorIds: array of connector ids used by the flow
forms: optional; PingOne Forms definitions keyed by UUID
```

**(b) Wrapper**: `{ flows: [...], forms: {...} }`:

```text
flows[]: one entry per flow (subflows included); each entry has its own
                  graphData and connectorIds
forms: PingOne Forms definitions keyed by UUID
```

In both shapes, `forms[<uuid>].components` is an object containing a `fields` array whose entries carry the collector types (`type` such as `TEXT`, `PASSWORD`, `SUBMIT_BUTTON`, `FIDO2`, `SOCIAL_LOGIN_BUTTON`).

## Analysis Steps

**A1: Detect the envelope.** Check for a root `graphData`. Present: single-flow envelope, the flow object is the file root. Absent: wrapper envelope, expect `flows[]` and `forms`. Record the envelope; A2-A5 run per flow, A6-A8 summarize across all of them.

**A2: Enumerate flows.** Single-flow: the root flow. Wrapper: list every entry in `flows[]`, subflows included. Each entry carries its own `graphData` and is analyzed in full, not just the entry flow.

**A3: Collect node patterns.** For every flow, read `graphData.elements.nodes[].data`. Keep only nodes with `data.nodeType == "CONNECTION"`, and record for each:

- `data.connectorId` and `data.capabilityName`
- `data.properties.deviceType.value`, when present
- whether `data.properties.idpList` exists, and its `constructType`

Skip everything else: `EVAL` nodes carry neither a meaningful `connectorId` nor `capabilityName` (at most `id`, `label`, `properties`), and `ANNOTATION` nodes may carry connector-like metadata copied from the node they annotate: they are comments, not flow logic. Filter strictly on `nodeType == "CONNECTION"`; never infer from field presence.

**A4: Map node patterns to integrations.** Classify every recorded node with this table (parallel to Journey's node-to-callback table):

| Row | `connectorId` / `capabilityName` | Match condition | Integration | Confidence |
|---|---|---|---|---|
| 1 | `pingOneFormsConnector` / `customForm` | `properties.idpList` with `constructType: skConnectorList` | Social login (`rn-external-idp`) | Confirmed |
| 2 | `httpConnector` / `customHTMLTemplate` | `properties.idpList` with `constructType: skConnectorList` | Social login (`rn-external-idp`) | Unconfirmed |
| 3 | `pingOneRiskConnector` / `createRiskEvaluation`, `updateRiskEvaluation` | none: the connector id is the signal | Protect (`rn-protect`) | Candidate only |
| 4 | `pingOneMfaConnector` / `createDevice`, `createDeviceAuthentication`, `validateAssertionDeviceAuthentication` | `properties.deviceType.value == "FIDO2"` | FIDO passkeys (`rn-fido`) | Confirmed |
| 5 | `pingOneMfaConnector` / any other capability (e.g. `activateDevice`) | `deviceType` absent or a non-`FIDO2` value | No mapping: the connector also serves other device types | n/a |

Notes:

- Never key a match on the connector ids inside `idpList` entries (`pingOneAuthenticationConnector`, `googleConnector`, `facebookIdpConnector`, `appleConnector` have all been observed): they vary per environment. Key on `idpList` presence and `constructType` only.
- **Do not count providers from the `idpList` entry count.** The entries carry only `connectionId`/`connectorId`/`properties` (no provider names), and their count does not match the number of social buttons: a real export has one `idpList` entry but two `SOCIAL_LOGIN_BUTTON` form fields (Facebook, Google). Provider details (count, names, labels) come from the linked form's `SOCIAL_LOGIN_BUTTON` fields via A5, each carrying `idpId`, `idpName`, `idpType`, and `label`; the node match only establishes that the step uses social login.
- A node matching no row goes to `unrecognizedConnectors` (A7): report it, do not guess.

**A5: Preview core collectors.** When `forms` is present (root or wrapper; run this regardless of which envelope was detected), link each `customForm` node's `properties.form.value` (a form UUID) to its entry in `forms`, then map that form's `components.fields[]` entry `type` values to collector types. Types such as `ERROR_DISPLAY` or `SLATE_TEXTBLOB` are console-rendering helpers with no runtime collector counterpart; report them as-is. The preview is informational: the runtime `ContinueNode` remains the authoritative collector source. When `forms` is absent, `customForm` nodes carry only the UUID: list the form IDs and tell the user the fields must be checked in PingOne Forms.

**A6: Determine collector tier.**

- Any row-4 (FIDO2) or row-3 (Protect) match → pre-select **standard** (FIDO2/Protect signals → Standard or higher).
- Any row-1 (social login on `customForm`) match → pre-select **full**; a row-2 (`customHTMLTemplate`) match pre-selects **full** only with user confirmation.
- No integration matches → pre-select **basic**.

This is a pre-selection, not a decision: the wizard confirms the tier with the user at its collector-tier question, and that confirmation is where Protect's candidate status is resolved (see Special Cases). Always emit a tier from A6 so the wizard receives a pre-selection.

**A7: Extract wizard configuration.**

- `collectorTier`: from A6.
- `integrationPackages`: packages implied by the pre-selected tier, each marked with its confidence; Protect is flagged candidate and its inclusion is confirmed at the tier question.
- `formIds`: forms needing manual inspection (A5 fallback path).
- `unrecognizedConnectors`: connector ids that matched no table row.

**A8: Report, then generate.** Output a plain-text summary (envelope, flows analyzed, node-to-integration mapping with per-package confidence, collector preview or form-ID fallback, suggested tier) before writing any TypeScript/TSX. State per-package confidence explicitly. Never echo environment identifiers, and never write them into generated files.

## Special Cases

**customHTMLTemplate idpList.** Row-2 matches are unconfirmed: whether these nodes emit a native `SOCIAL_LOGIN_BUTTON` collector is unverified. List them separately in the report and let the user decide.

**Protect-only flows.** Real Protect flow exports contain no `PROTECT` component in their forms, so whether the server emits a native `PROTECT` collector is unverified. A row-3 match still pre-selects **standard** (A6) and the report marks `rn-protect` as candidate; the wizard's tier question is where the user confirms whether Protect is actually used.

**Subflows.** Wrapper exports include subflows as additional `flows[]` entries. Analyze every entry: an integration may live in a subflow while the entry flow only references it.
