# product_configuration_facebook_marketing

This folder is a thin product overlay for OpenClaw targeting Facebook Marketing use cases.

The shared provisioning logic lives in `https://github.com/puboc/feature_common`. This repo keeps only the Facebook Marketing-specific product files and its `setup.sh` clones the shared core, checks out the requested ref, sources `feature_common/lib/api.sh`, and runs the shared flow directly.

## Product Files
- `user_data.yml`: cloud-init bootstrap only.
- `setup.sh`: clones and launches `feature_common`.
- `templates/AGENTS.md`: Facebook Marketing-specific workspace operating guide.

## Provisioning Flow
1. Cloud-init installs base dependencies from `runcmd`.
2. Cloud-init clones this repository and runs `setup.sh`.
3. `setup.sh` clones `feature_common` and sources `feature_common/lib/api.sh`.
4. `setup.sh` runs the shared provisioning flow directly.

## Required Placeholder Values
Replace these placeholders before launching if your renderer does not auto-fill:
- `githubToken`
- `openClawGatewayToken`
- `telegramBotToken`
- `telegramUserId`
- `openRouterApiKey`
- `openAiCodexAccessToken`
- `openAiCodexRefreshToken`
- `openAiCodexExpires`
- `openAiEmail`
- `defaultModel` (`5.4-mini`, `5.3`, or `5.4`)

Optional shared-core controls:
- `FEATURE_COMMON_REPO_URL` (defaults to `https://github.com/puboc/feature_common.git`)
- `FEATURE_COMMON_REPO_REF` (defaults to `main`)
- `FEATURE_COMMON_DIR` (defaults to `/opt/feature_common`)
- `FEATURE_COMMON_GITHUB_TOKEN` (defaults to the embedded feature-common clone token in `setup.sh`)

Runtime behavior, output signals, and Telegram control-plane behavior come from `feature_common`.
