# Photography Collection Scripts

These scripts manage the photography collections on your website. They handle uploading photos to Cloudflare R2, updating the site's JSON metadata, and creating the necessary pages.

## Prerequisites
The scripts require `rclone` and `jq` to be installed (`brew install rclone jq`).

By default, the scripts look for your local photos in `~/Photography`. If you store them in Dropbox, you can create a symlink so the scripts find them automatically:
```bash
ln -s ~/Dropbox/Photography ~/Photography
```

---

## 1. Adding a New Collection

First, create a folder and add your photos locally (e.g., `~/Photography/iceland/`). Then run the add script from the root of your repo:
```bash
./scripts/add-collection.sh <slug> "<Title>" "<Location>" "<Date (YYYY-MM)>" "[Description]" "[Cover_Image.jpg]"
```

**Example:**
```bash
./scripts/add-collection.sh iceland "Iceland Ring Road" "Iceland" "2024-08" "Two weeks on the road." 001.jpg
```

This script will automatically:
1. Sync the photos to R2 (`photos.andrewguo.com/photography/iceland/`).
2. Add an entry to `photography/collections.yaml`.
3. Create the collection page folder (`photography/iceland/index.html`).
4. Git commit and push the changes.

## 2. Adding Captions

You **do not** need to edit any HTML to add captions or reorder photos! 
Open `photography/collections.yaml`, find the collection, and add a `"caption"` field to the specific photo. The gallery and lightbox will automatically read and display it.

```yaml
"photos": [
  { "file": "001.jpg", "caption": "Seljalandsfoss at midnight" },
  { "file": "002.jpg" }
]
```

## 3. Updating / Re-syncing Photos

If you edit, add, or replace photos in your local folder, just re-sync them to R2:
```bash
# Sync one collection
./scripts/sync-photos.sh iceland

# Sync all collections
./scripts/sync-photos.sh --all
```
*Note: If you add new photos locally, remember to manually add their filenames to `photography/collections.yaml` so they actually show up on the webpage.*

## 4. Removing a Collection

To completely delete a collection from the live site, R2, and `collections.yaml`:
```bash
./scripts/remove-collection.sh iceland
```
*(This will safely remove everything from the web, but it will NOT delete your local files in `~/Photography/iceland/`)*
