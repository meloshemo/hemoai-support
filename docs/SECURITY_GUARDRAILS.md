# Security Guardrails

To minimise the risk of leaking credentials or sensitive health data, the
repository now includes several automated protections.

## 1. Encrypted environment vault

- Script: `tool/env_vault.mjs`
- Enforces AES-256-GCM encryption for `.env` files.
- Output (`env.secrets.enc.json`) can be committed safely.
- See `docs/ENV_VAULT.md` for detailed usage.

## 2. Pre-commit secret scanning

- Tool: [pre-commit](https://pre-commit.com/)
- Configuration: `.pre-commit-config.yaml`
- Hook: `tool/hooks/check_secrets.sh`

### Setup

```bash
pip install pre-commit
pre-commit install
```

With the hook installed, any staged change containing high-risk tokens
(`SENDGRID_API_KEY`, `STRIPE_SECRET`, private keys, etc.) will block the commit.
Plaintext `.env` files are also rejected.

## 3. GitHub Actions guardrails

- Screenshot workflow now uploads SHA-256 manifests and fails on unexpected
  pixel or file-size drift.
- Uptime monitor workflow continuously pings the Functions health endpoint
  (requires `HEALTHCHECK_URL` secret).

## 4. Structured backend logging

- Firebase Functions emit structured JSON logs with request IDs to simplify
  correlation.
- Sensitive values (card data, API keys) are explicitly omitted from logs.

## 5. Next steps (recommended)

- Enable organisation-wide secret scanning via GitHub Advanced Security (if available).
- Add `gitleaks` or `trufflehog` to CI for belt-and-braces protection.
- Periodically rotate the vault passphrase and regenerate encrypted payloads.

