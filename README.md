# omp-bin

[AUR](https://aur.archlinux.org/packages/omp-bin) packaging for
[oh-my-pi](https://github.com/can1357/oh-my-pi) (`omp`) — the prebuilt release
binary, with automatic upstream tracking via [nvchecker](https://github.com/lilydjwg/nvchecker).

This repository is **not** the AUR repo itself. It is the source-of-truth that
builds, tests, and publishes the `omp-bin` PKGBUILD to the AUR whenever upstream
ships a new release.

## What it installs

- `/usr/bin/omp` — the `omp-linux-x64` / `omp-linux-arm64` release binary
- Shell completions for bash, zsh, and fish — generated at package time by
  running `omp completions <shell>`
- The MIT license

Supports `x86_64` and `aarch64`. The only dependency is `glibc` (Bun statically
bundles everything else).

The package sets `provides=(oh-my-pi=$pkgver)`, so it conflicts with the
`oh-my-pi` and `oh-my-pi-bin` packages (which also provide `oh-my-pi`), and with
the unrelated `omp` package over `/usr/bin/omp`.

## How auto-update works

`.github/workflows/update.yml` runs on a daily cron and on demand
(`workflow_dispatch`):

1. `nvchecker --failures` checks the latest stable release of `can1357/oh-my-pi`.
2. If it is newer than `pkgver`, `scripts/update.sh <version>` bumps
   `pkgver`/`pkgrel` and reads the SHA-256 sums from each release asset's `digest`
   field via the GitHub REST API — so the binaries are never downloaded just to
   checksum.
3. `makepkg` build-tests the package.
4. [`KSXGitHub/github-actions-deploy-aur`](https://github.com/KSXGitHub/github-actions-deploy-aur)
   publishes to the AUR. The action regenerates `.SRCINFO` from the PKGBUILD
   itself, so that is what lands in the AUR — the `.SRCINFO` committed here is
   only for local reference and the first-time manual import.
5. `nvtake` advances the nvchecker state, and the bumped files plus `old.json`
   are committed back to this repo.

## Required GitHub secrets

| Secret | Purpose |
| --- | --- |
| `AUR_USERNAME` | Git commit author name for the AUR push |
| `AUR_EMAIL` | Git commit author email for the AUR push |
| `AUR_SSH_PRIVATE_KEY` | Private key whose public half is registered on your AUR account |

`GITHUB_TOKEN` is provided automatically by Actions and only raises the GitHub
API rate limit for nvchecker and the digest lookup.

## Manual local update

```sh
GITHUB_TOKEN=ghp_xxx scripts/update.sh 15.9.1
```

The script also regenerates `.SRCINFO`.

## First-time AUR import

```sh
git clone ssh://aur@aur.archlinux.org/omp-bin.git aur
cp PKGBUILD .SRCINFO aur/
cd aur && git add PKGBUILD .SRCINFO && git commit -m "initial import" && git push
```
