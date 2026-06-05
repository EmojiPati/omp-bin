#!/usr/bin/env bash
# Bump the omp-bin PKGBUILD to <version>, reading checksums from each GitHub
# release-asset's `digest` field so the ~170 MB binaries never get downloaded.
set -euo pipefail

NEW_VER="${1:?usage: update.sh <version-without-v-prefix>}"
REPO="can1357/oh-my-pi"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKGBUILD="${HERE}/PKGBUILD"

AUTH=()
[[ -n "${GITHUB_TOKEN:-}" ]] && AUTH=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

api() {
    curl -fsSL -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" "${AUTH[@]}" "$1"
}

echo ">> Resolving checksums for v${NEW_VER} ..."
REL_JSON="$(api "https://api.github.com/repos/${REPO}/releases/tags/v${NEW_VER}")"

digest_for() {
    local asset="$1"
    echo "${REL_JSON}" | python3 -c "
import json,sys
rel=json.load(sys.stdin)
for a in rel.get('assets',[]):
    if a['name']=='${asset}':
        d=a.get('digest') or ''
        if d.startswith('sha256:'):
            print(d.split(':',1)[1]); sys.exit(0)
        sys.exit('asset ${asset} has no sha256 digest (got: %r)' % a.get('digest'))
sys.exit('asset ${asset} not found in release')
"
}

SHA_X64="$(digest_for omp-linux-x64)"
SHA_ARM="$(digest_for omp-linux-arm64)"
SHA_LICENSE="$(curl -fsSL "https://raw.githubusercontent.com/${REPO}/v${NEW_VER}/LICENSE" | sha256sum | cut -d' ' -f1)"

echo "   x86_64 : ${SHA_X64}"
echo "   aarch64: ${SHA_ARM}"
echo "   LICENSE: ${SHA_LICENSE}"

echo ">> Rewriting PKGBUILD ..."
sed -i \
    -e "s/^pkgver=.*/pkgver=${NEW_VER}/" \
    -e "s/^pkgrel=.*/pkgrel=1/" \
    -e "s/^sha256sums=('[0-9a-f]*')/sha256sums=('${SHA_LICENSE}')/" \
    -e "s/^sha256sums_x86_64=('[0-9a-f]*')/sha256sums_x86_64=('${SHA_X64}')/" \
    -e "s/^sha256sums_aarch64=('[0-9a-f]*')/sha256sums_aarch64=('${SHA_ARM}')/" \
    "${PKGBUILD}"

echo ">> Regenerating .SRCINFO ..."
( cd "${HERE}" && makepkg --printsrcinfo > .SRCINFO )

echo ">> Done: omp-bin is now at ${NEW_VER}"
