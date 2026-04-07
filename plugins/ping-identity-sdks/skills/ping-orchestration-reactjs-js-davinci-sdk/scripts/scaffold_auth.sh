#!/usr/bin/env bash
# ============================================================================
# Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.
# ============================================================================
#
# scaffold_auth.sh — Scaffold a React + Vite DaVinci authentication app.
#
# Usage:
#   ./scaffold_auth.sh <project_dir>
#
# Example:
#   ./scaffold_auth.sh ./my-davinci-app
# ============================================================================

set -euo pipefail

# ---------- Resolve the directory where this script lives ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="${SCRIPT_DIR}/../assets"

# ---------- Validate arguments ----------
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project_dir>"
  exit 1
fi

PROJECT_DIR="$1"

echo "🚀 Scaffolding DaVinci React app into: ${PROJECT_DIR}"

# ---------- Create project structure ----------
mkdir -p "${PROJECT_DIR}/src/components/collectors"
mkdir -p "${PROJECT_DIR}/src/hooks"
mkdir -p "${PROJECT_DIR}/src/pages"
mkdir -p "${PROJECT_DIR}/public"

# ---------- Helper: copy a template, stripping the .template suffix ----------
copy_template() {
  local src="$1"
  local dest="$2"
  cp "${src}" "${dest}"
  echo "  ✅ ${dest}"
}

# ---------- Root files ----------
copy_template "${ASSETS_DIR}/package.json.template"     "${PROJECT_DIR}/package.json"
copy_template "${ASSETS_DIR}/vite.config.js.template"    "${PROJECT_DIR}/vite.config.js"
copy_template "${ASSETS_DIR}/index.html.template"        "${PROJECT_DIR}/index.html"
copy_template "${ASSETS_DIR}/.env.template"              "${PROJECT_DIR}/.env"

# ---------- Source files ----------
copy_template "${ASSETS_DIR}/constants.js.template"      "${PROJECT_DIR}/src/constants.js"
copy_template "${ASSETS_DIR}/app.jsx.template"           "${PROJECT_DIR}/src/app.jsx"

# ---------- Hooks ----------
copy_template "${ASSETS_DIR}/use-davinci.hook.js.template" "${PROJECT_DIR}/src/hooks/use-davinci.hook.js"

# ---------- Pages ----------
copy_template "${ASSETS_DIR}/login.jsx.template"         "${PROJECT_DIR}/src/pages/login.jsx"
copy_template "${ASSETS_DIR}/callback.jsx.template"      "${PROJECT_DIR}/src/pages/callback.jsx"

# ---------- Components ----------
copy_template "${ASSETS_DIR}/form.jsx.template"          "${PROJECT_DIR}/src/components/form.jsx"

# ---------- Collector components ----------
copy_template "${ASSETS_DIR}/text.jsx.template"              "${PROJECT_DIR}/src/components/collectors/text.jsx"
copy_template "${ASSETS_DIR}/password.jsx.template"          "${PROJECT_DIR}/src/components/collectors/password.jsx"
copy_template "${ASSETS_DIR}/submit-button.jsx.template"     "${PROJECT_DIR}/src/components/collectors/submit-button.jsx"
copy_template "${ASSETS_DIR}/flow-button.jsx.template"       "${PROJECT_DIR}/src/components/collectors/flow-button.jsx"
copy_template "${ASSETS_DIR}/single-select.jsx.template"     "${PROJECT_DIR}/src/components/collectors/single-select.jsx"
copy_template "${ASSETS_DIR}/multi-select.jsx.template"      "${PROJECT_DIR}/src/components/collectors/multi-select.jsx"
copy_template "${ASSETS_DIR}/read-only.jsx.template"         "${PROJECT_DIR}/src/components/collectors/read-only.jsx"
copy_template "${ASSETS_DIR}/phone-number.jsx.template"      "${PROJECT_DIR}/src/components/collectors/phone-number.jsx"
copy_template "${ASSETS_DIR}/device-registration.jsx.template" "${PROJECT_DIR}/src/components/collectors/device-registration.jsx"
copy_template "${ASSETS_DIR}/device-authentication.jsx.template" "${PROJECT_DIR}/src/components/collectors/device-authentication.jsx"
copy_template "${ASSETS_DIR}/social-login-button.jsx.template" "${PROJECT_DIR}/src/components/collectors/social-login-button.jsx"
copy_template "${ASSETS_DIR}/protect.jsx.template"           "${PROJECT_DIR}/src/components/collectors/protect.jsx"
copy_template "${ASSETS_DIR}/fido-registration.jsx.template"  "${PROJECT_DIR}/src/components/collectors/fido-registration.jsx"
copy_template "${ASSETS_DIR}/fido-authentication.jsx.template" "${PROJECT_DIR}/src/components/collectors/fido-authentication.jsx"

# ---------- Create main.jsx entry point ----------
cat > "${PROJECT_DIR}/src/main.jsx" << 'EOF'
/* ============================================================================
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 * ========================================================================== */

import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './app';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
EOF
echo "  ✅ ${PROJECT_DIR}/src/main.jsx"

# ---------- Done ----------
echo ""
echo "✨ Scaffolding complete!"
echo ""
echo "Next steps:"
echo "  1. cd ${PROJECT_DIR}"
echo "  2. Edit .env with your PingOne credentials"
echo "  3. npm install"
echo "  4. npm run dev"
