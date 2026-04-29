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

OPENCLAW_BASE_DIR="${OPENCLAW_BASE_DIR:-/opt/openclaw}"
OPENCLAW_WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-${OPENCLAW_BASE_DIR}/data/.openclaw/workspace}"
FB_ENV_PATH="${FB_ENV_PATH:-${OPENCLAW_WORKSPACE_DIR}/fb_env}"
SKILLS_DIR="${SKILLS_DIR:-${OPENCLAW_WORKSPACE_DIR}/skills}"
FB_SKILL_ZIP="${FB_SKILL_ZIP:-${SCRIPT_DIR}/skills/facebook-skill-latest.zip}"

fingerprint_value() {
  python3 -c 'import hashlib,sys; print(hashlib.sha256(sys.stdin.buffer.read().rstrip(b"\n")).hexdigest()[:12])' <<< "$1"
}

write_fb_env() {
  local fb_env_dir
  fb_env_dir="$(dirname -- "${FB_ENV_PATH}")"

  log_info "LABEL write_fb_env:start"
  log_info "Facebook env write starting path=${FB_ENV_PATH} dir=${fb_env_dir}"

  install -d "${fb_env_dir}"
  log_info "Facebook env directory ready dir=${fb_env_dir} exists=$([[ -d "${fb_env_dir}" ]] && printf true || printf false)"

  cat > "${FB_ENV_PATH}" <<EOF
FB_APP_ID=${FB_APP_ID}
FB_APP_SECRET=${FB_APP_SECRET}
FB_SHORT_LIVE_TOKEN=${FB_SHORT_LIVE_TOKEN}
FB_PAGE_ID=${FB_PAGE_ID}
FB_AD_ACCOUNT_ID=${FB_AD_ACCOUNT_ID}
EOF
  log_info "Facebook env file write command completed path=${FB_ENV_PATH}"

  chmod 0600 "${FB_ENV_PATH}"
  log_info "Facebook env file chmod completed path=${FB_ENV_PATH} mode=$(stat -c '%a' "${FB_ENV_PATH}" 2>/dev/null || stat -f '%Lp' "${FB_ENV_PATH}") bytes=$(wc -c < "${FB_ENV_PATH}")"

  log_info "Facebook env vars written app_id_sha256=$(fingerprint_value "${FB_APP_ID}") page_id=${FB_PAGE_ID} ad_account_id=${FB_AD_ACCOUNT_ID}"
  log_info "Facebook env written path=${FB_ENV_PATH} has_app_id=$(grep -q '^FB_APP_ID=' "${FB_ENV_PATH}" && printf true || printf false) has_app_secret=$(grep -q '^FB_APP_SECRET=' "${FB_ENV_PATH}" && printf true || printf false) has_short_live_token=$(grep -q '^FB_SHORT_LIVE_TOKEN=' "${FB_ENV_PATH}" && printf true || printf false)"
  log_info "LABEL write_fb_env:done"
}

install_facebook_skill() {
  log_info "LABEL install_facebook_skill:start"
  log_info "Facebook skill install starting zip=${FB_SKILL_ZIP} skills_dir=${SKILLS_DIR}"

  if [[ ! -f "${FB_SKILL_ZIP}" ]]; then
    log_info "Facebook skill zip not found path=${FB_SKILL_ZIP}" >&2
    exit 1
  fi

  install -d "${SKILLS_DIR}"
  log_info "Facebook skill directory ready dir=${SKILLS_DIR} exists=$([[ -d "${SKILLS_DIR}" ]] && printf true || printf false)"

  unzip -o "${FB_SKILL_ZIP}" -d "${SKILLS_DIR}"
  log_info "Facebook skill unzipped dir=${SKILLS_DIR}/facebook"

  chmod -R 0755 "${SKILLS_DIR}/facebook/scripts/"
  log_info "Facebook skill scripts chmod completed"

  log_info "LABEL install_facebook_skill:done"
}

fc::init_runtime_context
fc::register_agents_template "${AGENTS_TEMPLATE}"

fc::prepare_host
fc::write_runtime_env
fc::run_step "write-fb-env" write_fb_env
fc::run_step "install-facebook-skill" install_facebook_skill
fc::install_state_patch
fc::run_openclaw_container
fc::find_openclaw_config
fc::configure_telegram_channel
fc::ensure_openclaw_config_permissions "initial"
fc::ensure_state_patch_ready "initial"
fc::post_openclaw_state 1
fc::run_runtime_defaults_pass "pass1"
fc::install_workspace_guide
fc::restart_openclaw "after-workspace-guide"
fc::sleep_step "sleep-after-openclaw-restart" 10
fc::ensure_state_patch_ready "second"
fc::run_runtime_defaults_pass "pass2"
fc::install_control_plane
fc::run_runtime_defaults_pass "pass3"
fc::ensure_support_patch
fc::post_openclaw_state 2
fc::write_provision_success
log_info "Setup completed successfully"
