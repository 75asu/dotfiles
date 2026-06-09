# webfetch

Render any URL with headless Chromium (Playwright) and emit clean markdown, plain
text, or the rendered HTML. Local, OSS, **no API key**, nothing leaves your machine.
Handles JS-rendered SPAs (the reason a plain `curl` fails on sites like Google Careers).

Pipeline: Playwright (Chromium renders the JS) -> Mozilla Readability (main-content
extraction) -> Turndown (HTML -> markdown).

## Usage

```bash
webfetch https://example.com                      # clean markdown to stdout
webfetch https://example.com -o page.md           # to a file
webfetch https://example.com --text               # plain text
webfetch https://example.com --raw                # whole page (skip Readability)
webfetch https://example.com --html               # rendered post-JS HTML
webfetch https://spa.example.com --wait 3000       # extra settle time for heavy SPAs
webfetch https://example.com --selector ".jobDesc" # wait for a selector first
webfetch https://example.com --screenshot shot.png
```

## Install

Handled by `mac-install.sh` / `linux-install.sh` (runs `npm ci` + `playwright install
chromium` here, then symlinks `~/.local/bin/webfetch`). Manual:

```bash
cd tools/webfetch && npm ci && npx playwright install chromium
ln -sf "$PWD/webfetch" ~/.local/bin/webfetch
```

On Linux, Chromium needs system libraries: `npx playwright install-deps chromium` (sudo).
