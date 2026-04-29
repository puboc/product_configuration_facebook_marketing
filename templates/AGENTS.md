# Facebook Marketing Agent Guide

## Purpose
This workspace is prepared for a Facebook Marketing OpenClaw deployment with Telegram allowlist enabled for exactly one operator account.

## Runtime Facts
- OpenClaw API port: `56073`
- Provision progress API: `http://127.0.0.1:56073/state`
- Workspace root: `/data/.openclaw/workspace`
- OpenClaw config path (inside container): `/data/.openclaw/openclaw.json`
- Progress state file (inside container): `/data/progress/state.json`
- Action file watched by worker: `/opt/openclaw/data/telegram-action.txt`
- Auth profiles path: `/data/.openclaw/agents/main/agent/auth-profiles.json`
- OAuth env file on host: `/opt/openclaw/data/openai-codex-oauth.env`

## Telegram Safety Rules
- Keep `channels.telegram.enabled = true`.
- Keep `channels.telegram.dmPolicy = "allowlist"`.
- Keep `channels.telegram.groupPolicy = "allowlist"`.
- Keep exactly one value in `channels.telegram.allowFrom` unless the operator asks to expand access.

## Operational Rules
- Do not rotate tokens automatically.
- Do not remove mounted paths under `/data`.
- If restart is required, prefer `docker restart openclaw`.
- If config edits are made, write valid JSON and keep a trailing newline.
