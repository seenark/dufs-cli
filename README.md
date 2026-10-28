# dufs-cli

[dufs](https://github.com/sigoden/dufs) in Docker (`compose.yaml`) plus `pub`, a small bash CLI that publishes files and folders into the directory dufs serves.

## Run dufs

```sh
docker compose up -d
```

Serves `PUB_ROOT` (default `~/pub`) on `127.0.0.1:5000`, localhost only. The Cloudflare tunnel in front of it is your own setup, not part of this repo.

## Use `pub` from any project

Symlink `pub` into a folder on your `PATH`:

```sh
ln -s <repo>/pub ~/.local/bin/pub
```

Set these in your shell profile:

```sh
export PUB_URL=https://read.yourdomain.com   # default: https://read.yourdomain.com
export PUB_ROOT=~/pub                        # optional, default: ~/pub
```

## Commands

| Command | What it does | Example |
| --- | --- | --- |
| `pub path <slug>` | Create the page folder, print its path | `pub path notes` |
| `pub add <slug> <file\|dir>` | Publish a file (`.html`/`.htm` becomes `index.html`) or a dir's contents; print the URL | `pub add notes report.html` |
| `pub url <slug>` | Print the URL, touches nothing | `pub url notes` |
| `pub ls` | List pages, newest first | `pub ls` |
| `pub rm <slug>` | Delete the page folder | `pub rm notes` |
| `pub help` | Show usage | `pub help` |
