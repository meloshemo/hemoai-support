#!/usr/bin/env bash
set -euo pipefail

# Abort if backup/export files detected
violations=0
for file in "$@"; do
  if [[ "$file" == *"data/backups/"* ]] || [[ "$file" == *.export.json ]] || [[ "$file" == *.dump.json ]] || [[ "$file" == *.pii.json ]]; then
    echo "[PII BLOCK] File matches forbidden pattern: $file" >&2
    violations=1
  fi
  # Lightweight content scan for typical hemogram dump markers
  if [[ -f "$file" ]] && grep -E -q "(hemogram_dump|wbc|rbc|hemoglobin|hematocrit)" "$file"; then
    # Only warn for code files, block for obvious dumps (json/csv/txt)
    ext="${file##*.}"
    if [[ "$ext" == "json" || "$ext" == "csv" || "$ext" == "txt" ]]; then
      echo "[PII BLOCK] Potential health data dump content found in $file" >&2
      violations=1
    fi
  fi
done

if [[ $violations -ne 0 ]];
then
  cat >&2 <<'EOF'
Commit blocked due to potential PII/health data. Please remove dumps or add to .gitignore:
 - data/backups/
 - *.export.json
 - *.dump.json
 - *.pii.json
EOF
  exit 1
fi

exit 0
