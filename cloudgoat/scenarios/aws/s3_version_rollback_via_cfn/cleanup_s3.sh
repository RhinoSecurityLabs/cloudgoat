#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_FILE="$SCRIPT_DIR/start.txt"

if [[ ! -f "$START_FILE" ]]; then
  echo "❌ start.txt not found in $SCRIPT_DIR"
  exit 1
fi

PROFILE=$(grep "^profile" "$START_FILE" | cut -d'=' -f2 | tr -d ' ')
CGID=$(grep "^cgid" "$START_FILE" | cut -d'=' -f2 | tr -d ' ')

if [[ -z "$PROFILE" || -z "$CGID" ]]; then
  echo "❌ Failed to extract profile or cgid from start.txt"
  exit 1
fi

INDEX_BUCKET="cg-s3-version-index-${CGID}"
FLAG_BUCKET="cg-s3-version-flag-${CGID}"

echo "[✔] Using AWS profile: $PROFILE"
echo "[✔] CGID: $CGID"
echo "[+] Buckets to clean: $INDEX_BUCKET, $FLAG_BUCKET"

delete_all_versions() {
  local bucket_name=$1
  local use_bypass=$2
  local raw_file="raw-versions-${bucket_name}.json"
  local wrapped_file="objects-to-delete-${bucket_name}.json"

  echo "[*] Listing versions in $bucket_name..."
  aws s3api list-object-versions \
    --bucket "$bucket_name" \
    --profile "$PROFILE" \
    --output json \
    --query="Versions[].{Key: Key, VersionId: VersionId}" > "$raw_file"

  if [[ $(wc -c < "$raw_file") -gt 5 ]]; then
    echo "{\"Objects\": $(cat "$raw_file")}" > "$wrapped_file"

    echo "[*] Deleting versions in $bucket_name..."
    if [[ "$use_bypass" == "true" ]]; then
      aws s3api delete-objects \
        --bucket "$bucket_name" \
        --profile "$PROFILE" \
        --delete file://"$wrapped_file" \
        --bypass-governance-retention || echo "[!] Some deletions may have failed"
    else
      aws s3api delete-objects \
        --bucket "$bucket_name" \
        --profile "$PROFILE" \
        --delete file://"$wrapped_file" || echo "[!] Some deletions may have failed"
    fi

    rm -f "$wrapped_file"
  else
    echo "[ℹ️] No object versions to delete in $bucket_name"
  fi

  rm -f "$raw_file"
  echo "[✔] Done cleaning: $bucket_name"
}

delete_all_versions "$INDEX_BUCKET" "true"
delete_all_versions "$FLAG_BUCKET" "false"

echo "[✅] All S3 cleanup complete using profile: $PROFILE"
