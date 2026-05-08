# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development

No build step or toolchain required.

```bash
# Local preview
python3 -m http.server 8000
open http://localhost:8000
```

Deployment is automatic on push to `main` via GitHub Pages at andrewguo.com.

## Architecture

Single-page static site. All content lives in `index.html` (markup + inline JS) and `stylesheet.css`. Assets go in `images/` (photos, thumbnails, demo videos, favicons) and `data/` (resume PDF). Publication project pages live under `pub/<project>/index.html` as HTML redirects to external pages.

Key patterns in `index.html`:
- Table-based layout for the publication list (thumbnail/video left, text right)
- Inline JS functions (e.g. `dark3r_start()` / `dark3r_stop()`) swap static thumbnails for autoplay videos on hover
- CSS classes `.papertitle`, `.highlight`, `.name` are shared across publication entries

## Conventions

- Two-space indentation in HTML and CSS
- Relative paths for all assets (GitHub Pages requirement)
- Reuse existing CSS classes before adding new selectors
