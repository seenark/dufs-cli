---
name: publish-html
description: Publish an HTML page (file or folder) with the pub CLI to get a permanent URL. Use when the user wants to share a page or get a link to read on a phone. Not for deploying real websites.
---

# publish-html

Publish HTML and reply with its permanent URL.

1. Run `command -v pub`. If missing, stop and tell the user to install it per the README. Never create or copy the CLI yourself.
2. Pick a slug from the content: lowercase, hyphen-separated.
3. Run `pub ls`. If the slug is already listed, ask the user to overwrite or pick another name. Skip the question only if the user said to update that page.
4. The source is one `.html` file or a folder (for CSS, images). Write newly generated HTML to a temp file first.
5. Run `pub add <slug> <file|dir>`. Reply with the URL it printed, verbatim (it ends in `/`). Never build the URL by hand.

## Deleting

Run `pub rm <slug>` only when the user asks to delete that page. Report the slug you removed.
