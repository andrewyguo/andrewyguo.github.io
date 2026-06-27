#!/bin/bash
set -euo pipefail

# ============================================================
# sync-photos.sh — Re-sync photos for an existing collection (or all).
#
# Usage:
#   ./scripts/sync-photos.sh <slug>     # sync one collection
#   ./scripts/sync-photos.sh --all      # sync everything
#
# Use when you've added/removed/replaced photos in your local folder.
# ============================================================

LOCAL_PHOTOS_DIR="${PHOTOGRAPHY_DIR:-$HOME/Photography}"
R2_REMOTE="r2:andrewguo-photos/photography"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <slug>   or   $0 --all"
  exit 1
fi

if [ "$1" = "--all" ]; then
  echo "☁️  Syncing ALL collections to R2..."
  rclone sync "$LOCAL_PHOTOS_DIR/" "$R2_REMOTE/" --progress --transfers 8
else
  SLUG="$1"
  PHOTO_SRC="$LOCAL_PHOTOS_DIR/$SLUG"
  if [ ! -d "$PHOTO_SRC" ]; then
    echo "❌ Folder not found: $PHOTO_SRC"
    exit 1
  fi
  echo "☁️  Syncing '$SLUG' to R2..."
  rclone sync "$PHOTO_SRC" "$R2_REMOTE/$SLUG/" --progress --transfers 8
fi

echo "✅ Sync complete."
