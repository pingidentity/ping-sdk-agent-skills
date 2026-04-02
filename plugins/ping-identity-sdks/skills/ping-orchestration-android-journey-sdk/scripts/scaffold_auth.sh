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
JOURNEY_NAME="Login"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --package)   PACKAGE="$2";      shift 2 ;;
        --src-dir)   SRC_DIR="$2";      shift 2 ;;
        --journey)   JOURNEY_NAME="$2"; shift 2 ;;
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
CALLBACK_DIR="$AUTH_DIR/callback"

copy_template() {
    local template="$1"
    local dest="$2"
    if [[ ! -f "$template" ]]; then echo "Template not found: $template"; return; fi
    if [[ -f "$dest" ]]; then echo "Already exists: $dest"; return; fi
    mkdir -p "$(dirname "$dest")"
    sed -e "s|com\.example\.myapp|$PACKAGE|g" -e "s|\"Login\"|\"$JOURNEY_NAME\"|g" "$template" > "$dest"
    echo "Created: $dest"
}

echo "Scaffolding Ping Identity Journey auth..."
echo "  Package: $PACKAGE | Src: $SRC_DIR | Journey: $JOURNEY_NAME"

copy_template "$ASSETS_DIR/JourneyConfig.kt.template"  "$AUTH_DIR/JourneyConfig.kt"
copy_template "$ASSETS_DIR/AuthState.kt.template"       "$AUTH_DIR/AuthState.kt"
copy_template "$ASSETS_DIR/AuthViewModel.kt.template"   "$AUTH_DIR/AuthViewModel.kt"
copy_template "$ASSETS_DIR/AuthScreen.kt.template"      "$AUTH_DIR/AuthScreen.kt"
copy_template "$ASSETS_DIR/CallbackNode.kt.template"    "$CALLBACK_DIR/CallbackNode.kt"
copy_template "$ASSETS_DIR/CallbackFields.kt.template"  "$CALLBACK_DIR/CallbackFields.kt"

echo "Done! Fill in JourneyConfig.kt with your PingOne AIC details."
