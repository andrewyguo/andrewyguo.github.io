#!/bin/bash
set -euo pipefail

# ============================================================
# add-collection.sh — Add a new photography collection in one move.
#
# Usage:
#   ./scripts/add-collection.sh <slug> <title> <location> <date> [description] [cover_filename]
#
# Example:
#   ./scripts/add-collection.sh iceland "Iceland Ring Road" "Iceland" "2024-08" "Two weeks on the ring road." cover.jpg
#
# What it does:
#   1. Reads photos from your local photography folder (~/.photography/<slug>/)
#   2. Syncs that folder to Cloudflare R2
#   3. Adds the collection entry to photography/collections.json
#   4. Copies the collection page template to photography/<slug>/
#   5. Git add + commit + push
#
# Prerequisites:
#   - rclone configured with R2 remote (see scripts/setup-r2.md)
#   - jq installed (brew install jq)
#   - Photos already in LOCAL_PHOTOS_DIR/<slug>/
# ============================================================

# ── Config (edit these once) ──────────────────────────────────
# Where you keep photos locally (e.g. a Dropbox folder, iCloud, or just ~/Photography)
LOCAL_PHOTOS_DIR="${PHOTOGRAPHY_DIR:-$HOME/Photography}"

# rclone remote name + bucket (set up during rclone config)
R2_REMOTE="r2:andrewguo-photos/photography"

# Repo root (auto-detected from script location)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# ──────────────────────────────────────────────────────────────

# ── Parse args ────────────────────────────────────────────────
if [ $# -lt 4 ]; then
  echo "Usage: $0 <slug> <title> <location> <date> [description] [cover_filename]"
  echo ""
  echo "Example:"
  echo "  $0 iceland \"Iceland Ring Road\" \"Iceland\" \"2024-08\" \"Two weeks on the ring road.\" 001.jpg"
  exit 1
fi

SLUG="$1"
TITLE="$2"
LOCATION="$3"
DATE="$4"
DESCRIPTION="${5:-}"
COVER="${6:-}"

PHOTO_SRC="$LOCAL_PHOTOS_DIR/$SLUG"
COLLECTIONS_YAML="$REPO_ROOT/photography/collections.yaml"
TEMPLATE_DIR="$REPO_ROOT/photography/_template"
DEST_DIR="$REPO_ROOT/photography/$SLUG"

# ── Validate ──────────────────────────────────────────────────
if [ ! -d "$PHOTO_SRC" ]; then
  echo "❌ Photo folder not found: $PHOTO_SRC"
  echo "   Put your photos there first, then re-run."
  exit 1
fi

if [ -d "$DEST_DIR" ]; then
  echo "❌ Collection '$SLUG' already exists at $DEST_DIR"
  echo "   To update photos, run: ./scripts/sync-photos.sh $SLUG"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "❌ jq is required. Install with: brew install jq"
  exit 1
fi

if ! command -v yq &> /dev/null; then
  echo "❌ yq is required. Install with: brew install yq"
  exit 1
fi

if ! command -v rclone &> /dev/null; then
  echo "❌ rclone is required. Install with: brew install rclone"
  exit 1
fi

# ── Discover photos ───────────────────────────────────────────
echo "📸 Discovering photos in $PHOTO_SRC..."
PHOTOS=()
while IFS= read -r -d '' file; do
  PHOTOS+=("$(basename "$file")")
done < <(find "$PHOTO_SRC" -maxdepth 1 \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 | sort -z)

if [ ${#PHOTOS[@]} -eq 0 ]; then
  echo "❌ No images found in $PHOTO_SRC"
  exit 1
fi

echo "   Found ${#PHOTOS[@]} photos."

# Use first photo as cover if not specified
if [ -z "$COVER" ]; then
  COVER="${PHOTOS[0]}"
  echo "   Using '$COVER' as cover (first photo). Override with 6th argument."
fi

# ── Sync to R2 ────────────────────────────────────────────────
echo "☁️  Syncing to R2..."
rclone sync "$PHOTO_SRC" "$R2_REMOTE/$SLUG/" --progress --transfers 8
echo "   ✅ Photos live on R2."

# ── Build photo list JSON ─────────────────────────────────────
PHOTOS_JSON="["
for i in "${!PHOTOS[@]}"; do
  [ $i -gt 0 ] && PHOTOS_JSON+=","
  PHOTOS_JSON+="{\"file\":\"${PHOTOS[$i]}\"}"
done
PHOTOS_JSON+="]"

# ── Update collections.yaml ───────────────────────────────────
echo "📝 Updating collections.yaml..."

NEW_ENTRY=$(jq -n \
  --arg slug "$SLUG" \
  --arg title "$TITLE" \
  --arg location "$LOCATION" \
  --arg date "$DATE" \
  --arg description "$DESCRIPTION" \
  --arg cover "$COVER" \
  --argjson photos "$PHOTOS_JSON" \
  '{slug: $slug, title: $title, location: $location, date: $date, cover: $cover, description: $description, photos: $photos}')

# Convert YAML to JSON, append with jq, then convert back to YAML
yq -o=json "$COLLECTIONS_YAML" | \
jq --argjson entry "$NEW_ENTRY" '. + [$entry] | sort_by(.date) | reverse' | \
yq -P > "$COLLECTIONS_YAML.tmp" && mv "$COLLECTIONS_YAML.tmp" "$COLLECTIONS_YAML"

echo "   ✅ Added '$TITLE' to collections.yaml"

# ── Copy template page ────────────────────────────────────────
echo "📄 Creating collection page..."
cp -r "$TEMPLATE_DIR" "$DEST_DIR"
echo "   ✅ Created photography/$SLUG/"

# ── Git commit + push ─────────────────────────────────────────
echo "🚀 Committing and pushing..."
cd "$REPO_ROOT"
git add "photography/"
git commit -m "Add photography collection: $TITLE"
git push

echo ""
echo "✅ Done! '$TITLE' is live."
echo "   Gallery: https://andrewguo.com/photography/"
echo "   Collection: https://andrewguo.com/photography/$SLUG/"
