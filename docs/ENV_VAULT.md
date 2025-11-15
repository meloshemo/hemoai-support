# Environment Vault (`env.secrets.enc.json`)

To keep sensitive API keys out of the repository while still enabling safe
sharing within the team, use the Node-based vault helper located at
`tool/env_vault.mjs`.

## Prerequisites

- Node.js ≥ 18 (already available via Flutter toolchain or the Firebase CLI).
- A strong passphrase. For automation, store it in a secure secret manager and
  expose it as the `HEMOAI_VAULT_KEY` environment variable.

## Encrypting a `.env` file

```bash
# Example: encrypt the local .env file
node tool/env_vault.mjs encrypt \
  --input .env.local \
  --output env.secrets.enc.json \
  --passphrase "choose-a-strong-passphrase"
```

The command writes an AES-256-GCM payload (`env.secrets.enc.json`) containing:

- Derived key parameters (`salt`, `iv`, `authTag`)
- Base64 encoded ciphertext

It is safe to commit the encrypted JSON to the repository. The plaintext `.env`
file and intermediate outputs are ignored via `.gitignore`.

## Decrypting

```bash
node tool/env_vault.mjs decrypt \
  --input env.secrets.enc.json \
  --output .env.local \
  --passphrase "choose-a-strong-passphrase"
```

If `--passphrase` is omitted, the script reads `HEMOAI_VAULT_KEY`.

> **Tip:** Automate decryption inside CI by setting `HEMOAI_VAULT_KEY` as a
> repository or environment secret, then running the decrypt command before
> builds.

## Rotating secrets

1. Regenerate the plaintext `.env.local` with updated keys.
2. Re-encrypt with a fresh passphrase (or re-use the existing one).
3. Commit the new `env.secrets.enc.json`.
4. Share the passphrase out-of-band with authorized collaborators only.

## Security Notes

- AES-256-GCM provides authenticated encryption. Any tampering with the encrypted
  file will be detected during decryption.
- Change the passphrase if you suspect disclosure. Re-encrypt immediately.
- Never commit plaintext `.env` files; the `.gitignore` rules enforce this.

