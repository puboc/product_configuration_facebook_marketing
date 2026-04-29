#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_COMMON_REPO_URL="${FEATURE_COMMON_REPO_URL:-https://github.com/puboc/feature_common.git}"
FEATURE_COMMON_REPO_REF="${FEATURE_COMMON_REPO_REF:-main}"
FEATURE_COMMON_DIR="${FEATURE_COMMON_DIR:-/opt/feature_common}"
FEATURE_COMMON_GITHUB_TOKEN="${FEATURE_COMMON_GITHUB_TOKEN:-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}"

require_file() {
  local path="$1"
  if [[ ! -f "${path}" ]]; then
    echo "Missing required file: ${path}" >&2
    exit 1
  fi
}

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 1
  fi
}

build_clone_url() {
  local url="$1"
  case "${url}" in
    https://github.com/*)
      printf 'https://x-access-token:%s@github.com/%s' "${FEATURE_COMMON_GITHUB_TOKEN}" "${url#https://github.com/}"
      ;;
    *)
      printf '%s' "${url}"
      ;;
  esac
}

require_var FEATURE_COMMON_GITHUB_TOKEN
require_var FB_APP_ID
require_var FB_APP_SECRET
require_var FB_SHORT_LIVE_TOKEN
require_var FB_PAGE_ID
require_var FB_AD_ACCOUNT_ID

AGENTS_TEMPLATE="${AGENTS_TEMPLATE:-${SCRIPT_DIR}/templates/AGENTS.md}"
require_file "${AGENTS_TEMPLATE}"

clone_url="$(build_clone_url "${FEATURE_COMMON_REPO_URL}")"

rm -rf "${FEATURE_COMMON_DIR}"
git clone "${clone_url}" "${FEATURE_COMMON_DIR}"

if ! git -C "${FEATURE_COMMON_DIR}" checkout "${FEATURE_COMMON_REPO_REF}"; then
  echo "Checkout failed for feature_common ref: ${FEATURE_COMMON_REPO_REF}" >&2
  git -C "${FEATURE_COMMON_DIR}" branch -a >&2 || true
  exit 1
fi

# shellcheck disable=SC1091
source "${FEATURE_COMMON_DIR}/lib/api.sh"

fc::init_runtime_context
fc::register_agents_template "${AGENTS_TEMPLATE}"
fc::run_default_setup
