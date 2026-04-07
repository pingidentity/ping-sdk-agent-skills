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
set -euo pipefail

TARGET_DIR="."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target-dir) TARGET_DIR="$2"; shift 2 ;;
        --help)       sed -n '2,20p' "$0"; exit 0 ;;
        *)            echo "Unknown option: $1"; exit 1 ;;
    esac
done

VIEWMODELS_DIR="$TARGET_DIR/ViewModels"
VIEWS_DIR="$TARGET_DIR/Views"
COLLECTOR_VIEWS_DIR="$VIEWS_DIR/Collectors"

copy_template() {
    local template="$1"
    local dest="$2"
    if [[ ! -f "$template" ]]; then echo "Template not found: $template"; return; fi
    if [[ -f "$dest" ]]; then echo "Already exists: $dest"; return; fi
    mkdir -p "$(dirname "$dest")"
    cp "$template" "$dest"
    echo "Created: $dest"
}

echo "Scaffolding Ping Orchestration iOS SDK (DaVinci module) auth..."
echo "  Target: $TARGET_DIR"

# ViewModels
copy_template "$ASSETS_DIR/DavinciViewModel.swift.template"   "$VIEWMODELS_DIR/DavinciViewModel.swift"
copy_template "$ASSETS_DIR/ValidationViewModel.swift.template" "$VIEWMODELS_DIR/ValidationViewModel.swift"

# Main views
copy_template "$ASSETS_DIR/DavinciView.swift.template"        "$VIEWS_DIR/DavinciView.swift"
copy_template "$ASSETS_DIR/ContinueNodeView.swift.template"   "$VIEWS_DIR/ContinueNodeView.swift"

# Collector views
copy_template "$ASSETS_DIR/TextView.swift.template"                "$COLLECTOR_VIEWS_DIR/TextView.swift"
copy_template "$ASSETS_DIR/PasswordView.swift.template"            "$COLLECTOR_VIEWS_DIR/PasswordView.swift"
copy_template "$ASSETS_DIR/SubmitButtonView.swift.template"        "$COLLECTOR_VIEWS_DIR/SubmitButtonView.swift"
copy_template "$ASSETS_DIR/FlowButtonView.swift.template"          "$COLLECTOR_VIEWS_DIR/FlowButtonView.swift"
copy_template "$ASSETS_DIR/LabelView.swift.template"               "$COLLECTOR_VIEWS_DIR/LabelView.swift"
copy_template "$ASSETS_DIR/DropdownView.swift.template"            "$COLLECTOR_VIEWS_DIR/DropdownView.swift"
copy_template "$ASSETS_DIR/RadioButtonView.swift.template"         "$COLLECTOR_VIEWS_DIR/RadioButtonView.swift"
copy_template "$ASSETS_DIR/CheckBoxView.swift.template"            "$COLLECTOR_VIEWS_DIR/CheckBoxView.swift"
copy_template "$ASSETS_DIR/ComboBoxView.swift.template"            "$COLLECTOR_VIEWS_DIR/ComboBoxView.swift"
copy_template "$ASSETS_DIR/PhoneNumberView.swift.template"         "$COLLECTOR_VIEWS_DIR/PhoneNumberView.swift"
copy_template "$ASSETS_DIR/DeviceRegistrationView.swift.template"  "$COLLECTOR_VIEWS_DIR/DeviceRegistrationView.swift"
copy_template "$ASSETS_DIR/DeviceAuthenticationView.swift.template" "$COLLECTOR_VIEWS_DIR/DeviceAuthenticationView.swift"
copy_template "$ASSETS_DIR/SocialButtonView.swift.template"        "$COLLECTOR_VIEWS_DIR/SocialButtonView.swift"
copy_template "$ASSETS_DIR/PingProtectView.swift.template"         "$COLLECTOR_VIEWS_DIR/PingProtectView.swift"
copy_template "$ASSETS_DIR/FidoRegistrationView.swift.template"     "$COLLECTOR_VIEWS_DIR/FidoRegistrationView.swift"
copy_template "$ASSETS_DIR/FidoAuthenticationView.swift.template"   "$COLLECTOR_VIEWS_DIR/FidoAuthenticationView.swift"

echo "Done! Fill in DavinciViewModel.swift with your PingOne DaVinci details."
