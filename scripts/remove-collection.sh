#!/bin/bash
set -euo pipefail

# ============================================================
# remove-collection.sh — Remove a photography collection.
#
# Usage:
#   ./scripts/remove-collection.sh <slug>
#
# What it does:
#   1. Removes photos from R2
#   2. Removes the entry from collections.json
#   3. Removes the collection page folder
#   4. Git commit + push
# ============================================================

LOCAL_PHOTOS_DIR="${PHOTOGRAPHY_DIR:-$HOME/Photography}"
R2_REMOTE="r2:andrewguo-photos/photography"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <slug>"
  exit 1
fi

SLUG="$1"
COLLECTIONS_YAML="$REPO_ROOT/photography/collections.yaml"
DEST_DIR="$REPO_ROOT/photography/$SLUG"

echo "⚠️  This will remove collection '$SLUG' from:"
echo "   - R2 (remote photos)"
echo "   - collections.yaml"
echo "   - photography/$SLUG/ (site page)"
echo ""
echo "   Your local photos in $LOCAL_PHOTOS_DIR/$SLUG/ will NOT be deleted."
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

# Remove from R2
echo "☁️  Removing from R2..."
rclone purge "$R2_REMOTE/$SLUG/" 2>/dev/null || echo "   (nothing on R2 to remove)"

# Remove from collections.yaml
echo "📝 Updating collections.yaml..."
yq -o=json "$COLLECTIONS_YAML" | \
jq --arg slug "$SLUG" 'map(select(.slug != $slug))' | \
yq -P > "$COLLECTIONS_YAML.tmp" && mv "$COLLECTIONS_YAML.tmp" "$COLLECTIONS_YAML"

# Remove page folder
if [ -d "$DEST_DIR" ]; then
  rm -rf "$DEST_DIR"
  echo "📄 Removed photography/$SLUG/"
fi

# Git commit + push
cd "$REPO_ROOT"
git add "photography/"
git commit -m "Remove photography collection: $SLUG"
git push

echo "✅ Collection '$SLUG' removed."
