#!/usr/bin/env node
/**
 * Compare reconstructed screenshots against a baseline and optionally write diff images.
 * Fails with exit code 1 when the normalized pixel difference exceeds the threshold
 * or when expected files are missing/mismatched.
 */

import fs from 'fs';
import path from 'path';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';

function parseArgs(argv) {
  const args = new Map();
  for (let i = 2; i < argv.length; i += 1) {
    const key = argv[i];
    if (key.startsWith('--')) {
      const value = argv[i + 1]?.startsWith('--') || argv[i + 1] === undefined ? 'true' : argv[i + 1];
      if (value !== 'true') {
        i += 1;
      }
      args.set(key, value);
    }
  }
  return args;
}

const args = parseArgs(process.argv);
const baselineDir = path.resolve(args.get('--baseline') ?? 'tool/screenshot_baseline');
const currentDir = path.resolve(args.get('--current') ?? 'build/reconstructed_screenshots');
const diffDir = path.resolve(args.get('--diff') ?? 'build/diff');
const threshold = Number.parseFloat(args.get('--threshold') ?? '0.02');
const includeAA = args.get('--include-aa') !== 'false';

if (!fs.existsSync(baselineDir)) {
  console.log(`[compare_screenshots] Baseline directory not found: ${baselineDir}. Skipping diff.`);
  process.exit(0);
}

const baselinePngs = fs
  .readdirSync(baselineDir)
  .filter((file) => file.toLowerCase().endsWith('.png'))
  .sort();

if (baselinePngs.length === 0) {
  console.log('[compare_screenshots] No baseline PNGs found; nothing to compare.');
  process.exit(0);
}

if (!fs.existsSync(currentDir)) {
  console.error(`[compare_screenshots] Current screenshot directory missing: ${currentDir}`);
  process.exit(1);
}

fs.mkdirSync(diffDir, { recursive: true });

const failures = [];
const summaries = [];

for (const fileName of baselinePngs) {
  const baselinePath = path.join(baselineDir, fileName);
  const currentPath = path.join(currentDir, fileName);

  if (!fs.existsSync(currentPath)) {
    failures.push(`Missing current screenshot for ${fileName}`);
    continue;
  }

  const baselinePng = PNG.sync.read(fs.readFileSync(baselinePath));
  const currentPng = PNG.sync.read(fs.readFileSync(currentPath));

  if (baselinePng.width !== currentPng.width || baselinePng.height !== currentPng.height) {
    failures.push(
      `Dimension mismatch for ${fileName} (baseline ${baselinePng.width}x${baselinePng.height} vs current ${currentPng.width}x${currentPng.height})`,
    );
    continue;
  }

  const diff = new PNG({ width: baselinePng.width, height: baselinePng.height });
  const diffPixels = pixelmatch(
    baselinePng.data,
    currentPng.data,
    diff.data,
    baselinePng.width,
    baselinePng.height,
    {
      threshold: 0.1,
      alpha: 0.5,
      includeAA,
    },
  );

  const totalPixels = baselinePng.width * baselinePng.height;
  const diffRatio = diffPixels / totalPixels;
  const diffPercentage = (diffRatio * 100).toFixed(2);

  summaries.push(`${fileName}: ${diffPixels} px diff (${diffPercentage}%)`);

  if (diffPixels > 0) {
    const diffPath = path.join(diffDir, fileName.replace(/\.png$/i, '_diff.png'));
    fs.writeFileSync(diffPath, PNG.sync.write(diff));
  }

  if (diffRatio > threshold) {
    failures.push(
      `Pixel diff for ${fileName} exceeds threshold (${diffPercentage}% > ${(threshold * 100).toFixed(2)}%)`,
    );
  }
}

const currentPngs = fs
  .readdirSync(currentDir)
  .filter((file) => file.toLowerCase().endsWith('.png'))
  .sort();

for (const fileName of currentPngs) {
  if (!baselinePngs.includes(fileName)) {
    summaries.push(`${fileName}: New screenshot (no baseline to compare)`);
  }
}

console.log('[compare_screenshots] Comparison summary:');
for (const summary of summaries) {
  console.log(`  • ${summary}`);
}

if (failures.length > 0) {
  console.error('[compare_screenshots] Failures detected:');
  for (const failure of failures) {
    console.error(`  • ${failure}`);
  }
  process.exit(1);
}

console.log('[compare_screenshots] All comparisons within threshold.');

