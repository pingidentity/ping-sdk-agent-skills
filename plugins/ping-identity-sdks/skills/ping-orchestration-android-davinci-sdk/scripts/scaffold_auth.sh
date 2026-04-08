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

PACKAGE=""
SRC_DIR="app/src/main/java"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --package)   PACKAGE="$2";      shift 2 ;;
        --src-dir)   SRC_DIR="$2";      shift 2 ;;
        --help)      sed -n '2,25p' "$0"; exit 0 ;;
        *)           echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$PACKAGE" ]]; then
    echo "--package is required. Example: --package com.example.myapp"
    exit 1
fi

PACKAGE_PATH="${PACKAGE//./\/}"
AUTH_DIR="$SRC_DIR/$PACKAGE_PATH/auth"
COLLECTOR_DIR="$AUTH_DIR/collector"

copy_template() {
    local template="$1"
    local dest="$2"
    if [[ ! -f "$template" ]]; then echo "Template not found: $template"; return; fi
    if [[ -f "$dest" ]]; then echo "Already exists: $dest"; return; fi
    mkdir -p "$(dirname "$dest")"
    sed -e "s|com\.example\.myapp|$PACKAGE|g" "$template" > "$dest"
    echo "Created: $dest"
}

echo "Scaffolding Ping Orchestration Android SDK (DaVinci module) auth..."
echo "  Package: $PACKAGE | Src: $SRC_DIR"

# Core files
copy_template "$ASSETS_DIR/DaVinciConfig.kt.template"     "$AUTH_DIR/DaVinciConfig.kt"
copy_template "$ASSETS_DIR/DaVinciState.kt.template"      "$AUTH_DIR/DaVinciState.kt"
copy_template "$ASSETS_DIR/DaVinciViewModel.kt.template"  "$AUTH_DIR/DaVinciViewModel.kt"
copy_template "$ASSETS_DIR/DaVinciScreen.kt.template"     "$AUTH_DIR/DaVinciScreen.kt"

# Collector composables
copy_template "$ASSETS_DIR/ContinueNode.kt.template"      "$COLLECTOR_DIR/ContinueNode.kt"
copy_template "$ASSETS_DIR/Text.kt.template"               "$COLLECTOR_DIR/Text.kt"
copy_template "$ASSETS_DIR/Password.kt.template"           "$COLLECTOR_DIR/Password.kt"
copy_template "$ASSETS_DIR/SubmitButton.kt.template"       "$COLLECTOR_DIR/SubmitButton.kt"
copy_template "$ASSETS_DIR/FlowButton.kt.template"         "$COLLECTOR_DIR/FlowButton.kt"
copy_template "$ASSETS_DIR/Label.kt.template"              "$COLLECTOR_DIR/Label.kt"
copy_template "$ASSETS_DIR/Dropdown.kt.template"           "$COLLECTOR_DIR/Dropdown.kt"
copy_template "$ASSETS_DIR/Radio.kt.template"              "$COLLECTOR_DIR/Radio.kt"
copy_template "$ASSETS_DIR/CheckBox.kt.template"           "$COLLECTOR_DIR/CheckBox.kt"
copy_template "$ASSETS_DIR/ComboBox.kt.template"           "$COLLECTOR_DIR/ComboBox.kt"
copy_template "$ASSETS_DIR/PhoneNumber.kt.template"        "$COLLECTOR_DIR/PhoneNumber.kt"
copy_template "$ASSETS_DIR/DeviceRegistration.kt.template" "$COLLECTOR_DIR/DeviceRegistration.kt"
copy_template "$ASSETS_DIR/DeviceAuthentication.kt.template" "$COLLECTOR_DIR/DeviceAuthentication.kt"
copy_template "$ASSETS_DIR/SocialLoginButton.kt.template"  "$COLLECTOR_DIR/SocialLoginButton.kt"
copy_template "$ASSETS_DIR/Protect.kt.template"            "$COLLECTOR_DIR/Protect.kt"
copy_template "$ASSETS_DIR/FidoRegistration.kt.template"    "$COLLECTOR_DIR/FidoRegistration.kt"
copy_template "$ASSETS_DIR/FidoAuthentication.kt.template"  "$COLLECTOR_DIR/FidoAuthentication.kt"

echo "Done! Fill in DaVinciConfig.kt with your PingOne DaVinci details."
