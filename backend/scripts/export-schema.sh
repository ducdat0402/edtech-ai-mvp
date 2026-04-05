#!/usr/bin/env bash
# Export public schema DDL (no data). Requires pg_dump on PATH and DATABASE_URL in .env or env.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if [[ -z "${DATABASE_URL:-}" ]]; then
  DATABASE_URL="$(grep -E '^DATABASE_URL=' .env | head -1 | sed 's/^DATABASE_URL=//')"
fi
if [[ -z "${DATABASE_URL}" ]]; then
  echo "DATABASE_URL not set and not found in .env" >&2
  exit 1
fi
OUT="${1:-schema-export.sql}"
pg_dump "$DATABASE_URL" --schema=public --schema-only --no-owner --no-acl -f "$OUT"
node scripts/strip-pg-dump-meta.js "$OUT"
echo "Wrote $OUT"
