# Automated Project Creation — Steps 0–G

Read this file when `output-path` is provided in a `create-sample` invocation or when the user asks for Xcode project scaffolding.

---

## Step 0 — Detect XcodeBuildMCP and choose a scaffolding path

Before Step A, decide which of three scaffolding paths to take:

1. **MCP tools loaded.** Look for any tool whose name starts with `mcp__xcodebuildmcp__` in the available-tools list. If present → MCP path (Step A onward, using `mcp__xcodebuildmcp__*` calls).

2. **MCP tools absent but `xcodebuildmcp` CLI installed.** Check with `which xcodebuildmcp || command -v xcodebuildmcp`. If found → **CLI fallback path**. The same scaffolder is callable as a shell command:
   ```bash
   xcodebuildmcp project-scaffolding scaffold-ios \
     --project-name "<AppName>" \
     --output-path "<output-path>" \
     --bundle-identifier "com.example.<appname-lowercase>" \
     --display-name "<AppName>" \
     --deployment-target 18.0 \
     --marketing-version 1.0.0 \
     --current-project-version 1
   ```
   Run `xcodebuildmcp --help` to discover other subcommands. Prefer this path when the user wants results immediately — registering the MCP server requires a session restart, but the CLI works in the current session.

3. **Neither MCP tools nor CLI.** Ask the user with `AskUserQuestion`:

   - **Install XcodeBuildMCP (recommended)** — guide the user to install once, then re-run. Run from a fresh terminal:
     ```bash
     claude mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp
     ```
     Prerequisites: macOS 14.5+, Xcode 16+, Node 18+. After install, the user must restart this Claude Code session for the MCP tools to register, then re-invoke the same command.
     Source: https://xcodebuildmcp.com/docs/clients

   - **Use the Ruby `xcodeproj` gem fallback** — proceed without MCP or CLI. Requires the gem (`gem install xcodeproj`, version `>= 1.26.0`). Use Step A-Fallback below.

   Do not silently choose. If the user picks install-and-restart, halt execution after printing the install command.

---

## Output layout produced by the scaffolder

The scaffolder writes everything **directly into `<output-path>/`** — there is no `<AppName>/` parent directory wrapping the project:

```
<output-path>/
├── <AppName>.xcodeproj/      ← NOT under <AppName>/
├── <AppName>/                ← Swift source files go here
│   ├── Assets.xcassets/
│   └── (Swift files)
├── <AppName>UITests/
├── Config/
│   ├── Shared.xcconfig
│   ├── Debug.xcconfig
│   ├── Release.xcconfig
│   ├── Tests.xcconfig
│   └── <AppName>.entitlements
└── <AppName>Package/         ← deleted in Step B
```

So:
- `.xcodeproj` lives at `<output-path>/<AppName>.xcodeproj`
- Source files go in `<output-path>/<AppName>/`
- Config files go in `<output-path>/Config/`
- Ruby helper scripts go in `<output-path>/`

If the scaffolder's behaviour changes in a future release, run `ls <output-path>` after Step A and verify the layout before continuing.

---

## Step A — Scaffold the Xcode project (MCP path)

```
mcp__xcodebuildmcp__scaffold_ios_project(
  projectName: "<AppName>",
  outputPath: "<output-path>",
  bundleIdentifier: "com.example.<appname-lowercase>",
  displayName: "<AppName>",
  deploymentTarget: "18.0",
  marketingVersion: "1.0.0",
  currentProjectVersion: "1"
)
```

---

## Step A-Fallback — Scaffold the Xcode project (Ruby `xcodeproj` gem path)

Use only when XcodeBuildMCP is unavailable. First confirm the gem version:

```bash
ruby -rxcodeproj -e 'puts Xcodeproj::VERSION' || gem install xcodeproj
```

Write `<output-path>/scaffold.rb` and run with `ruby <output-path>/scaffold.rb`:

```ruby
require 'xcodeproj'
require 'fileutils'

APP        = "<AppName>"
BUNDLE_ID  = "com.example.<appname-lowercase>"
OUTPUT     = File.expand_path("<output-path>")
PROJECT_DIR = File.join(OUTPUT, APP)
SOURCE_DIR  = File.join(PROJECT_DIR, APP)
CONFIG_DIR  = File.join(PROJECT_DIR, "Config")

FileUtils.mkdir_p([SOURCE_DIR, CONFIG_DIR])

File.write(File.join(CONFIG_DIR, "Shared.xcconfig"), <<~XCCONFIG)
  IPHONEOS_DEPLOYMENT_TARGET = 18.0
  SWIFT_VERSION = 6.0
  PRODUCT_BUNDLE_IDENTIFIER = #{BUNDLE_ID}
  GENERATE_INFOPLIST_FILE = YES
  INFOPLIST_KEY_UILaunchScreen_Generation = YES
  INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES
  INFOPLIST_KEY_NSFaceIDUsageDescription = This app uses Face ID for biometric authentication.
  CODE_SIGN_ENTITLEMENTS = Config/#{APP}.entitlements
XCCONFIG

File.write(File.join(CONFIG_DIR, "#{APP}.entitlements"), <<~PLIST)
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0"><dict/></plist>
PLIST

project = Xcodeproj::Project.new(File.join(PROJECT_DIR, "#{APP}.xcodeproj"),
                                 false,
                                 Xcodeproj::Constants::DEFAULT_OBJECT_VERSION)
project.root_object.attributes['LastUpgradeCheck'] = '1600'

config_group = project.new_group('Config', 'Config')
xcconfig_ref = config_group.new_reference('Shared.xcconfig')
config_group.new_reference("#{APP}.entitlements")

target = project.new_target(:application, APP, :ios, '18.0')
target.build_configurations.each do |bc|
  bc.base_configuration_reference = xcconfig_ref
end

# Xcode 16 PBXFileSystemSynchronizedRootGroup — auto-syncs the source folder
sync = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
sync.path = APP
sync.source_tree = '<group>'
project.main_group << sync
target.file_system_synchronized_groups ||= []
target.file_system_synchronized_groups << sync

project.save
puts "Scaffolded #{APP}.xcodeproj at #{PROJECT_DIR}"
```

After this script runs, the project layout matches what XcodeBuildMCP would have produced (minus the local `<AppName>Package`). Skip Step B's `rm` of the local package. Continue with Step C onward.

Fallback **Step E replacement** — instead of `mcp__xcodebuildmcp__resolve_package_dependencies`, run:
```bash
xcodebuild -resolvePackageDependencies \
  -project "<output-path>/<AppName>.xcodeproj" \
  -scheme "<AppName>"
```

Fallback **Step G replacement** (see Step G for dynamic simulator detection):
```bash
xcodebuild build \
  -project "<output-path>/<AppName>.xcodeproj" \
  -scheme "<AppName>" \
  -destination "platform=iOS Simulator,name=$SIM_NAME,OS=latest"
```

---

## Step B — Delete scaffold artifacts that conflict with the app

```bash
rm -rf "<output-path>/<AppName>Package"
rm -rf "<output-path>/<AppName>.xcworkspace"
rm -f  "<output-path>/<AppName>/<AppName>App.swift"
```

---

## Step C — Add ping-ios-sdk SPM dependency and remove local-package wiring

Write a Ruby script to `<output-path>/add_spm_deps.rb` and run it with `ruby <output-path>/add_spm_deps.rb`.

The script must:
1. Open `<output-path>/<AppName>.xcodeproj` with `xcodeproj` (flat layout — no nested `<AppName>/` directory)
2. **Remove the local `<AppName>Feature` product dependency completely.** Match by **`product_name == "<AppName>Feature"` OR (`package` is nil AND `product_name` contains `"Feature"`)** — the local-package products have no `package` reference. For each match, remove:
   - The reference from every target's `packageProductDependencies` array (app target AND UITests target)
   - The corresponding `PBXBuildFile` entry from each target's frameworks build phase
   - The standalone `XCSwiftPackageProductDependency` block itself
3. Add the remote `ping-ios-sdk` package (`https://github.com/ForgeRock/ping-ios-sdk`, `upToNextMajorVersion >= 2.0.0`)
4. Link **only the products the flow actually needs** (see flow-specific lists in SKILL.md Section C or the tier table)
5. Save the project

After running the script, **immediately verify with a dry build**:
```bash
xcodebuild -project "<output-path>/<AppName>.xcodeproj" -scheme "<AppName>" -showBuildSettings >/dev/null 2>&1 \
  || echo "Project file is malformed — re-check Feature-product cleanup"
```

If a real build still complains about `Missing package product '<AppName>Feature'`, search manually:
```bash
grep -n "<AppName>Feature" <output-path>/<AppName>.xcodeproj/project.pbxproj
```
Every printed line must be deleted. Common straggler: standalone `XCSwiftPackageProductDependency` blocks at the end of the object table.

**Flow-specific product lists — choose based on `flowType` and `callbackTier`:**

| Flow + Tier | Products to link |
|---|---|
| Journey — Basic | `PingJourney`, `PingOidc`, `PingOrchestrate`, `PingLogger`, `PingJourneyPlugin` |
| Journey — Standard | `PingJourney`, `PingOidc`, `PingOrchestrate`, `PingLogger`, `PingJourneyPlugin`, `PingFido`, `PingProtect`, `PingBinding`, `PingDeviceProfile`, `PingExternalIdP` |
| Journey — Full fat | Everything in Standard + `PingReCaptchaEnterprise`, `PingExternalIdPApple`, `PingExternalIdPFacebook`, `PingExternalIdPGoogle` |
| OIDC Web (any tier) | `PingOidc`, `PingBrowser`, `PingStorage`, `PingLogger` |
| DaVinci — Basic | `PingDavinci`, `PingDavinciPlugin`, `PingOidc`, `PingOrchestrate`, `PingLogger` |
| DaVinci — Standard | `PingDavinci`, `PingDavinciPlugin`, `PingOidc`, `PingOrchestrate`, `PingLogger`, `PingFido`, `PingProtect` |
| DaVinci — Full fat | Everything in DaVinci Standard + `PingExternalIdP`, `PingExternalIdPApple`, `PingExternalIdPFacebook`, `PingExternalIdPGoogle` |

**SPM build_file wiring note:** Use `build_file.product_ref = dep` (not `build_file.file_ref = dep`) when wiring SPM product dependencies to a build phase.

---

## Step D — Configure xcconfig and entitlements

Edit `<output-path>/Config/Shared.xcconfig` — append or replace:
```
IPHONEOS_DEPLOYMENT_TARGET = 18.0
INFOPLIST_KEY_NSFaceIDUsageDescription = This app uses Face ID for biometric authentication.
```

**Do NOT add `INFOPLIST_KEY_CFBundleURLTypes[0].CFBundleURLSchemes[0]` to xcconfig** — the `[0]` array-subscript syntax produces `error: expected to find '=' in macro condition` at build time. Also, never write a hand-authored `Info.plist` — `PBXFileSystemSynchronizedRootGroup` auto-includes it and you'll get `error: Multiple commands produce Info.plist`.

**For OIDC Web flows** — register the URL scheme by setting the build setting directly on each `XCBuildConfiguration`. Write `<output-path>/add_url_scheme.rb` and run it:

```ruby
require 'xcodeproj'

PROJECT  = "<output-path>/<AppName>.xcodeproj"
TARGET   = "<AppName>"
SCHEME   = "<urlscheme>"   # the part of redirectUri before "://"

project = Xcodeproj::Project.open(PROJECT)
target  = project.targets.find { |t| t.name == TARGET } or abort("Target #{TARGET} not found")

target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_KEY_CFBundleURLTypes_0_CFBundleURLSchemes_0'] = SCHEME
end

project.save
puts "Registered URL scheme #{SCHEME} on #{TARGET}"
```

**For FIDO flows**, edit `<output-path>/Config/<AppName>.entitlements` — add:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>webcredentials:yourdomain.com</string>
    <string>webcredentials:yourdomain.com?mode=develop</string>
</array>
```

---

## Step E — Resolve SPM packages

MCP path:
```
mcp__xcodebuildmcp__resolve_package_dependencies(
  projectPath: "<output-path>/<AppName>.xcodeproj"
)
```

CLI fallback:
```bash
xcodebuild -resolvePackageDependencies \
  -project "<output-path>/<AppName>.xcodeproj" \
  -scheme "<AppName>"
```

---

## Step F — Write Swift source files

Write every generated `.swift` file to `<output-path>/<AppName>/`. The scaffold uses Xcode 16 `PBXFileSystemSynchronizedRootGroup` — files in this directory are picked up automatically without touching `project.pbxproj`.

**Copy the Ping Identity logo imageset** from the skill's bundled assets — do NOT search for it in DerivedData or other locations:

```bash
SKILL_ASSETS="$HOME/.claude/skills/ping-sdk-ios/assets"
DEST="<output-path>/<AppName>/Assets.xcassets/Logo.imageset"
mkdir -p "$DEST"
cp "$SKILL_ASSETS/Logo.imageset/Ping Identity Logo.png" "$DEST/"
cp "$SKILL_ASSETS/Logo.imageset/Contents.json" "$DEST/"
```

---

## Step G — Build and verify

Pick an available iPhone simulator dynamically — never hardcode `iPhone 16`. On Xcode 26+ installs only the latest iPhone family is available:

```bash
SIM_NAME=$(xcrun simctl list devices available -j | python3 -c '
import json, sys, re
data = json.load(sys.stdin)
candidates = []
for runtime, devs in data["devices"].items():
    if "iOS" not in runtime:
        continue
    for d in devs:
        name = d["name"]
        if name.startswith("iPhone") and "Pro" not in name and "Max" not in name and not name.endswith("e"):
            candidates.append(name)
def num(n):
    m = re.search(r"iPhone (\d+)", n)
    return int(m.group(1)) if m else 0
candidates.sort(key=num, reverse=True)
print(candidates[0] if candidates else "iPhone")
')
```

MCP path:
```
mcp__xcodebuildmcp__session_set_defaults(
  projectPath: "<output-path>/<AppName>.xcodeproj",
  scheme: "<AppName>",
  simulatorName: "$SIM_NAME",
  useLatestOS: true
)
mcp__xcodebuildmcp__build_sim({})
```

CLI fallback:
```bash
xcodebuild build \
  -project "<output-path>/<AppName>.xcodeproj" \
  -scheme "<AppName>" \
  -destination "platform=iOS Simulator,name=$SIM_NAME,OS=latest"
```

Report any compiler errors and fix them before declaring success.
