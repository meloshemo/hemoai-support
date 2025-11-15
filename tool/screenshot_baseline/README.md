# Screenshot Baseline

Place approved reference screenshots here (PNG format). The CI workflow compares
freshly reconstructed images in `build/reconstructed_screenshots` against these
baseline files using `tool/compare_screenshots.mjs`.

File naming must match between the baseline and the reconstructed output. When a
baseline is not present, the diff step is skipped.

