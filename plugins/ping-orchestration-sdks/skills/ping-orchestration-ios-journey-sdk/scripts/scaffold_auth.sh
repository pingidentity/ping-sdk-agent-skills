#!/usr/bin/env bash
#
# 
#
# scaffold_auth.sh
#
# Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.
#
# Scaffolds the Ping Orchestration iOS SDK (Journey module) authentication files into an iOS project.
#
# Usage:
#   ./scaffold_auth.sh --target MyApp [--journey Login]
#
# Options:
#   --target    Xcode target name / source directory (required)
#   --journey   Default Journey/Tree name (default: Login)
#   --help      Show this help message
#
set -euo pipefail

TARGET=""
JOURNEY_NAME="Login"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)    TARGET="$2";       shift 2 ;;
        --journey)   JOURNEY_NAME="$2"; shift 2 ;;
        --help)      sed -n '2,20p' "$0"; exit 0 ;;
        *)           echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    echo "Error: --target is required. Example: --target MyApp"
    exit 1
fi

BASE_DIR="$TARGET"
VIEWS_DIR="$BASE_DIR/Views"
VIEWMODELS_DIR="$BASE_DIR/ViewModels"
CALLBACKS_DIR="$BASE_DIR/Callbacks"

copy_template() {
    local template="$1"
    local dest="$2"
    if [[ ! -f "$template" ]]; then echo "Template not found: $template"; return; fi
    if [[ -f "$dest" ]]; then echo "Already exists: $dest"; return; fi
    mkdir -p "$(dirname "$dest")"
    sed -e "s|\"Login\"|\"$JOURNEY_NAME\"|g" "$template" > "$dest"
    echo "Created: $dest"
}

echo "Scaffolding Ping Orchestration iOS SDK (Journey module) auth..."
echo "  Target: $TARGET | Journey: $JOURNEY_NAME"
echo ""

# ── App Entry Point ───────────────────────────────────────────────────────────

copy_template "$ASSETS_DIR/App.swift.template"                "$BASE_DIR/App.swift"

# ── ViewModels ────────────────────────────────────────────────────────────────

copy_template "$ASSETS_DIR/JourneyViewModel.swift.template"   "$VIEWMODELS_DIR/JourneyViewModel.swift"
copy_template "$ASSETS_DIR/AccessTokenViewModel.swift.template" "$VIEWMODELS_DIR/AccessTokenViewModel.swift"
copy_template "$ASSETS_DIR/UserInfoViewModel.swift.template"   "$VIEWMODELS_DIR/UserInfoViewModel.swift"
copy_template "$ASSETS_DIR/LogOutViewModel.swift.template"     "$VIEWMODELS_DIR/LogOutViewModel.swift"

# ── Views ─────────────────────────────────────────────────────────────────────

copy_template "$ASSETS_DIR/ContentView.swift.template"        "$VIEWS_DIR/ContentView.swift"
copy_template "$ASSETS_DIR/JourneyView.swift.template"        "$VIEWS_DIR/JourneyView.swift"
copy_template "$ASSETS_DIR/CustomViews.swift.template"        "$VIEWS_DIR/CustomViews.swift"
copy_template "$ASSETS_DIR/ErrorView.swift.template"          "$VIEWS_DIR/ErrorView.swift"
copy_template "$ASSETS_DIR/AccessTokenView.swift.template"    "$VIEWS_DIR/AccessTokenView.swift"
copy_template "$ASSETS_DIR/UserInfoView.swift.template"       "$VIEWS_DIR/UserInfoView.swift"
copy_template "$ASSETS_DIR/LogOutView.swift.template"         "$VIEWS_DIR/LogOutView.swift"

# ── Callback Views ────────────────────────────────────────────────────────────

# Core callbacks
copy_template "$ASSETS_DIR/NameCallbackView.swift.template"                "$CALLBACKS_DIR/NameCallbackView.swift"
copy_template "$ASSETS_DIR/PasswordCallbackView.swift.template"            "$CALLBACKS_DIR/PasswordCallbackView.swift"
copy_template "$ASSETS_DIR/ValidatedUsernameCallbackView.swift.template"   "$CALLBACKS_DIR/ValidatedUsernameCallbackView.swift"
copy_template "$ASSETS_DIR/ValidatedPasswordCallbackView.swift.template"   "$CALLBACKS_DIR/ValidatedPasswordCallbackView.swift"
copy_template "$ASSETS_DIR/TextInputCallbackView.swift.template"           "$CALLBACKS_DIR/TextInputCallbackView.swift"
copy_template "$ASSETS_DIR/TextOutputCallbackView.swift.template"          "$CALLBACKS_DIR/TextOutputCallbackView.swift"
copy_template "$ASSETS_DIR/BooleanAttributeInputCallbackView.swift.template" "$CALLBACKS_DIR/BooleanAttributeInputCallbackView.swift"
copy_template "$ASSETS_DIR/NumberAttributeInputCallbackView.swift.template"  "$CALLBACKS_DIR/NumberAttributeInputCallbackView.swift"
copy_template "$ASSETS_DIR/StringAttributeInputCallbackView.swift.template"  "$CALLBACKS_DIR/StringAttributeInputCallbackView.swift"
copy_template "$ASSETS_DIR/ChoiceCallbackView.swift.template"              "$CALLBACKS_DIR/ChoiceCallbackView.swift"
copy_template "$ASSETS_DIR/ConfirmationCallbackView.swift.template"        "$CALLBACKS_DIR/ConfirmationCallbackView.swift"
copy_template "$ASSETS_DIR/KbaCreateCallbackView.swift.template"           "$CALLBACKS_DIR/KbaCreateCallbackView.swift"
copy_template "$ASSETS_DIR/TermsAndConditionsCallbackView.swift.template"  "$CALLBACKS_DIR/TermsAndConditionsCallbackView.swift"
copy_template "$ASSETS_DIR/ConsentMappingCallbackView.swift.template"      "$CALLBACKS_DIR/ConsentMappingCallbackView.swift"
copy_template "$ASSETS_DIR/PollingWaitCallbackView.swift.template"         "$CALLBACKS_DIR/PollingWaitCallbackView.swift"

# Optional callbacks
copy_template "$ASSETS_DIR/SelectIdpCallbackView.swift.template"                  "$CALLBACKS_DIR/SelectIdpCallbackView.swift"
copy_template "$ASSETS_DIR/IdpCallbackView.swift.template"                        "$CALLBACKS_DIR/IdpCallbackView.swift"
copy_template "$ASSETS_DIR/DeviceProfileCallbackView.swift.template"              "$CALLBACKS_DIR/DeviceProfileCallbackView.swift"
copy_template "$ASSETS_DIR/DeviceBindingCallbackView.swift.template"              "$CALLBACKS_DIR/DeviceBindingCallbackView.swift"
copy_template "$ASSETS_DIR/DeviceSigningVerifierCallbackView.swift.template"      "$CALLBACKS_DIR/DeviceSigningVerifierCallbackView.swift"
copy_template "$ASSETS_DIR/FidoRegistrationCallbackView.swift.template"           "$CALLBACKS_DIR/FidoRegistrationCallbackView.swift"
copy_template "$ASSETS_DIR/FidoAuthenticationCallbackView.swift.template"         "$CALLBACKS_DIR/FidoAuthenticationCallbackView.swift"
copy_template "$ASSETS_DIR/PingOneProtectInitializeCallbackView.swift.template"   "$CALLBACKS_DIR/PingOneProtectInitializeCallbackView.swift"
copy_template "$ASSETS_DIR/PingOneProtectEvaluationCallbackView.swift.template"   "$CALLBACKS_DIR/PingOneProtectEvaluationCallbackView.swift"
copy_template "$ASSETS_DIR/ReCaptchaEnterpriseCallbackView.swift.template"        "$CALLBACKS_DIR/ReCaptchaEnterpriseCallbackView.swift"

# ── Package.swift ─────────────────────────────────────────────────────────────

copy_template "$ASSETS_DIR/Package.swift.template"            "$BASE_DIR/../Package.swift"

echo ""
echo "Done! Next steps:"
echo "  1. Open the Xcode project and add the Ping iOS SDK via SPM."
echo "  2. Edit ViewModels/JourneyViewModel.swift with your PingAM/AIC server details."
echo "  3. Register optional callback modules in App.swift init()."
echo "  4. Add your custom URL scheme to Info.plist."
