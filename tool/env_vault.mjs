#!/usr/bin/env node

/**
 * HemoAI Environment Vault
 *
 * Encrypts or decrypts .env-style files into an AES-256-GCM protected JSON payload.
 *
 * Usage:
 *   node tool/env_vault.mjs encrypt --input .env.local --output env.secrets.enc.json --passphrase "my-strong-pass"
 *   node tool/env_vault.mjs decrypt --input env.secrets.enc.json --output .env.local --passphrase "my-strong-pass"
 *
 * Passphrase resolution order:
 *   1. --passphrase CLI argument
 *   2. HEMOAI_VAULT_KEY environment variable
 *
 * The resulting JSON contains:
 *   {
 *     "version": 1,
 *     "algorithm": "aes-256-gcm",
 *     "salt": "<base64>",
 *     "iv": "<base64>",
 *     "authTag": "<base64>",
 *     "ciphertext": "<base64>"
 *   }
 */

import fs from 'fs';
import path from 'path';
import { createCipheriv, createDecipheriv, pbkdf2Sync, randomBytes } from 'crypto';

const SUPPORTED_ACTIONS = new Set(['encrypt', 'decrypt']);

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith('--')) {
      if (!args._) args._ = [];
      args._.push(arg);
      continue;
    }
    const key = arg.slice(2);
    const value = argv[i + 1]?.startsWith('--') || argv[i + 1] === undefined ? true : argv[i + 1];
    if (value !== true) {
      i += 1;
    }
    args[key] = value;
  }
  return args;
}

function resolvePassphrase(args) {
  if (typeof args.passphrase === 'string' && args.passphrase.length > 0) {
    return args.passphrase;
  }
  if (process.env.HEMOAI_VAULT_KEY) {
    return process.env.HEMOAI_VAULT_KEY;
  }
  throw new Error('Passphrase not provided. Use --passphrase or set HEMOAI_VAULT_KEY.');
}

function ensurePath(value, key) {
  if (!value) {
    throw new Error(`Missing required argument --${key}`);
  }
  return path.resolve(value);
}

function deriveKey(passphrase, salt) {
  return pbkdf2Sync(passphrase, salt, 120000, 32, 'sha256');
}

function encryptFile(inputPath, outputPath, passphrase) {
  const plaintext = fs.readFileSync(inputPath, 'utf8');
  const salt = randomBytes(16);
  const iv = randomBytes(12); // GCM standard
  const key = deriveKey(passphrase, salt);

  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const ciphertext = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();

  const payload = {
    version: 1,
    algorithm: 'aes-256-gcm',
    salt: salt.toString('base64'),
    iv: iv.toString('base64'),
    authTag: authTag.toString('base64'),
    ciphertext: ciphertext.toString('base64'),
  };

  fs.writeFileSync(outputPath, JSON.stringify(payload, null, 2));
  console.log(`[env_vault] Encrypted ${inputPath} → ${outputPath}`);
}

function decryptFile(inputPath, outputPath, passphrase) {
  const raw = fs.readFileSync(inputPath, 'utf8');
  const payload = JSON.parse(raw);

  if (payload.algorithm !== 'aes-256-gcm') {
    throw new Error(`Unsupported algorithm: ${payload.algorithm}`);
  }

  const salt = Buffer.from(payload.salt, 'base64');
  const iv = Buffer.from(payload.iv, 'base64');
  const authTag = Buffer.from(payload.authTag, 'base64');
  const ciphertext = Buffer.from(payload.ciphertext, 'base64');

  const key = deriveKey(passphrase, salt);
  const decipher = createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(authTag);

  const plaintext = Buffer.concat([decipher.update(ciphertext), decipher.final()]).toString('utf8');
  fs.writeFileSync(outputPath, plaintext);
  console.log(`[env_vault] Decrypted ${inputPath} → ${outputPath}`);
}

function main() {
  const args = parseArgs(process.argv);
  const action = args._?.[0];

  if (!SUPPORTED_ACTIONS.has(action)) {
    console.error(`Usage: node tool/env_vault.mjs <encrypt|decrypt> --input <path> --output <path> [--passphrase <value>]`);
    process.exit(1);
  }

  const inputPath = ensurePath(args.input, 'input');
  const outputPath = ensurePath(args.output, 'output');
  const passphrase = resolvePassphrase(args);

  if (action === 'encrypt') {
    encryptFile(inputPath, outputPath, passphrase);
  } else {
    decryptFile(inputPath, outputPath, passphrase);
  }
}

try {
  main();
} catch (error) {
  console.error(`[env_vault] ${error.message}`);
  process.exit(1);
}

