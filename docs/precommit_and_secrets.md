# Pre-commit hooks and secrets hygiene

All contributors must enable the pre-commit hooks to guard against committing PII and secrets.

## Setup
1. Install pre-commit locally:
   - Windows PowerShell:
     - Install Python if needed, then:
       - `pip install pre-commit`
       - Run in repo root: `pre-commit install`
2. Verify hooks:
   - `pre-commit run --all-files`
   - Expect secret/PII scans to run and pass.

## Environment vault usage
We use `env_vault.mjs` to load environment variables safely for local tasks. Keep `.env*` out of source control unless explicitly whitelisted.

- To preview variables for tooling only, run:
  - `node env_vault.mjs print`
- Never commit real API keys or service account JSON.

## What the hooks do
- Scan staged files for:
  - Obvious secrets (API keys, tokens) via built-in detectors.
  - PII patterns and dumps (see `tool/hooks/check_pii.sh`).
- Block committing large data dumps and backup artifacts (`*.export.json`, `*.dump.json`, `*.pii.json`, `data/backups/`).

## Team policy
- Enable the hooks on first clone and keep them enabled.
- If a hook fails, fix the issue; don’t bypass unless release-blocking and approved.
- Before pushing, run CI locally where possible:
  - `flutter analyze` and `flutter test` should pass.

See also: `docs/publish_checklist.md` for release readiness.
