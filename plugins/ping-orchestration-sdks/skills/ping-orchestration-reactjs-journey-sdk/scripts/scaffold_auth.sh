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

# ── Ping Orchestration JavaScript SDK — ReactJS Scaffolding Script ────────────
#
# Copies all template files into a React project with the correct directory
# structure. Optionally substitutes the Journey name.
#
# Usage:
#   ./scaffold_auth.sh --project-dir ./my-react-app [--journey Login]
#
# This creates the following structure in your project:
#
#   <project-dir>/
#     ├── .env
#     ├── package.json
#     ├── vite.config.js
#     ├── public/
#     │   └── callback.html
#     └── client/
#         ├── index.html
#         ├── index.jsx
#         ├── constants.js
#         ├── router.jsx
#         ├── context/
#         │   └── oidc.context.js
#         ├── components/
#         │   ├── journey/
#         │   │   ├── form.jsx
#         │   │   ├── journey.hook.js
#         │   │   ├── text.jsx
#         │   │   ├── text-input.jsx
#         │   │   ├── password.jsx
#         │   │   ├── boolean.jsx
#         │   │   ├── number.jsx
#         │   │   ├── choice.jsx
#         │   │   ├── confirmation.jsx
#         │   │   ├── select-idp.jsx
#         │   │   ├── kba.jsx
#         │   │   ├── terms-conditions.jsx
#         │   │   ├── text-output.jsx
#         │   │   ├── suspended-text-output.jsx
#         │   │   ├── polling-wait.jsx
#         │   │   ├── redirect.jsx
#         │   │   ├── device-profile.jsx
#         │   │   ├── hidden-value.jsx
#         │   │   ├── metadata.jsx
#         │   │   ├── recaptcha.jsx
#         │   │   ├── recaptcha-enterprise.jsx
#         │   │   ├── protect-initialize.jsx
#         │   │   ├── protect-evaluation.jsx
#         │   │   ├── webauthn.jsx
#         │   │   └── unknown.jsx
#         │   └── utilities/
#         │       └── route.jsx
#         └── views/
#             ├── home.jsx
#             ├── login.jsx
#             ├── logout.jsx
#             └── register.jsx

PROJECT_DIR=""
JOURNEY_NAME="Login"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-dir) PROJECT_DIR="$2";    shift 2 ;;
        --journey)     JOURNEY_NAME="$2";   shift 2 ;;
        --help)        sed -n '2,40p' "$0"; exit 0 ;;
        *)             echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$PROJECT_DIR" ]]; then
    echo "--project-dir is required. Example: --project-dir ./my-react-app"
    exit 1
fi

copy_template() {
    local template="$1"
    local dest="$2"
    if [[ ! -f "$template" ]]; then echo "Template not found: $template"; return; fi
    if [[ -f "$dest" ]]; then echo "Already exists: $dest"; return; fi
    mkdir -p "$(dirname "$dest")"
    # Strip the .template extension content and substitute journey name
    sed -e "s|\"Login\"|\"$JOURNEY_NAME\"|g" "$template" > "$dest"
    echo "Created: $dest"
}

echo "Scaffolding Ping Orchestration JavaScript SDK (Journey) auth for ReactJS..."
echo "  Project: $PROJECT_DIR | Journey: $JOURNEY_NAME"
echo ""

# Root-level files
copy_template "$ASSETS_DIR/.env.template"              "$PROJECT_DIR/.env"
copy_template "$ASSETS_DIR/package.json.template"      "$PROJECT_DIR/package.json"
copy_template "$ASSETS_DIR/vite.config.js.template"    "$PROJECT_DIR/vite.config.js"

# Public directory
copy_template "$ASSETS_DIR/callback.html.template"     "$PROJECT_DIR/public/callback.html"

# Client entry
copy_template "$ASSETS_DIR/index.html.template"        "$PROJECT_DIR/client/index.html"
copy_template "$ASSETS_DIR/index.jsx.template"          "$PROJECT_DIR/client/index.jsx"
copy_template "$ASSETS_DIR/constants.js.template"       "$PROJECT_DIR/client/constants.js"
copy_template "$ASSETS_DIR/router.jsx.template"         "$PROJECT_DIR/client/router.jsx"

# Context
copy_template "$ASSETS_DIR/oidc.context.js.template"   "$PROJECT_DIR/client/context/oidc.context.js"

# Journey components
copy_template "$ASSETS_DIR/form.jsx.template"           "$PROJECT_DIR/client/components/journey/form.jsx"
copy_template "$ASSETS_DIR/journey.hook.js.template"    "$PROJECT_DIR/client/components/journey/journey.hook.js"
copy_template "$ASSETS_DIR/text.jsx.template"           "$PROJECT_DIR/client/components/journey/text.jsx"
copy_template "$ASSETS_DIR/text-input.jsx.template"     "$PROJECT_DIR/client/components/journey/text-input.jsx"
copy_template "$ASSETS_DIR/password.jsx.template"       "$PROJECT_DIR/client/components/journey/password.jsx"
copy_template "$ASSETS_DIR/boolean.jsx.template"        "$PROJECT_DIR/client/components/journey/boolean.jsx"
copy_template "$ASSETS_DIR/number.jsx.template"         "$PROJECT_DIR/client/components/journey/number.jsx"
copy_template "$ASSETS_DIR/choice.jsx.template"         "$PROJECT_DIR/client/components/journey/choice.jsx"
copy_template "$ASSETS_DIR/confirmation.jsx.template"   "$PROJECT_DIR/client/components/journey/confirmation.jsx"
copy_template "$ASSETS_DIR/select-idp.jsx.template"     "$PROJECT_DIR/client/components/journey/select-idp.jsx"
copy_template "$ASSETS_DIR/kba.jsx.template"            "$PROJECT_DIR/client/components/journey/kba.jsx"
copy_template "$ASSETS_DIR/terms-conditions.jsx.template" "$PROJECT_DIR/client/components/journey/terms-conditions.jsx"
copy_template "$ASSETS_DIR/text-output.jsx.template"    "$PROJECT_DIR/client/components/journey/text-output.jsx"
copy_template "$ASSETS_DIR/suspended-text-output.jsx.template" "$PROJECT_DIR/client/components/journey/suspended-text-output.jsx"
copy_template "$ASSETS_DIR/polling-wait.jsx.template"   "$PROJECT_DIR/client/components/journey/polling-wait.jsx"
copy_template "$ASSETS_DIR/redirect.jsx.template"       "$PROJECT_DIR/client/components/journey/redirect.jsx"
copy_template "$ASSETS_DIR/device-profile.jsx.template" "$PROJECT_DIR/client/components/journey/device-profile.jsx"
copy_template "$ASSETS_DIR/hidden-value.jsx.template"   "$PROJECT_DIR/client/components/journey/hidden-value.jsx"
copy_template "$ASSETS_DIR/metadata.jsx.template"       "$PROJECT_DIR/client/components/journey/metadata.jsx"
copy_template "$ASSETS_DIR/recaptcha.jsx.template"      "$PROJECT_DIR/client/components/journey/recaptcha.jsx"
copy_template "$ASSETS_DIR/recaptcha-enterprise.jsx.template" "$PROJECT_DIR/client/components/journey/recaptcha-enterprise.jsx"
copy_template "$ASSETS_DIR/protect-initialize.jsx.template" "$PROJECT_DIR/client/components/journey/protect-initialize.jsx"
copy_template "$ASSETS_DIR/protect-evaluation.jsx.template" "$PROJECT_DIR/client/components/journey/protect-evaluation.jsx"
copy_template "$ASSETS_DIR/webauthn.jsx.template"       "$PROJECT_DIR/client/components/journey/webauthn.jsx"
copy_template "$ASSETS_DIR/unknown.jsx.template"        "$PROJECT_DIR/client/components/journey/unknown.jsx"

# Utilities
copy_template "$ASSETS_DIR/route.jsx.template"          "$PROJECT_DIR/client/components/utilities/route.jsx"

# Views
copy_template "$ASSETS_DIR/home.jsx.template"           "$PROJECT_DIR/client/views/home.jsx"
copy_template "$ASSETS_DIR/login.jsx.template"          "$PROJECT_DIR/client/views/login.jsx"
copy_template "$ASSETS_DIR/logout.jsx.template"         "$PROJECT_DIR/client/views/logout.jsx"
copy_template "$ASSETS_DIR/register.jsx.template"       "$PROJECT_DIR/client/views/register.jsx"

echo ""
echo "Done! Next steps:"
echo "  1. cd $PROJECT_DIR"
echo "  2. Fill in your .env file with PingAM / AIC details"
echo "  3. npm install"
echo "  4. npm start"
