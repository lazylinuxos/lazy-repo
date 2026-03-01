#!/usr/bin/env bash

set -euo pipefail

printf "Checking latest version\n"

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GH_REPO="zen-browser/desktop"

LATEST_VERSION=$(
  gh release list \
    --repo "${GH_REPO}" \
    --json name,tagName,isLatest \
    --jq '.[] | select(.isLatest) | .tagName'
)

normalize_version() {
    local v="$1"

    local numeric suffix
    numeric=$(printf "%s" "$v" | grep -oE '^[0-9]+(\.[0-9]+)*')
    suffix=${v#$numeric}

    local dots
    dots=$(grep -o '\.' <<< "$numeric" | wc -l)

    if [ "$dots" -eq 1 ]; then
        numeric="${numeric}.0"
    fi

    printf "%s%s" "$numeric" "$suffix"
}

RAW_VERSION=${LATEST_VERSION#"v"}

export VERSION="$(normalize_version "$RAW_VERSION")"
export _VERSION="$RAW_VERSION"

CURRENT_VERSION=$(grep -E '^version=' "${__dir}/template" | cut -d= -f2)

printf "Latest upstream version: %s\n" "${_VERSION}"
printf "Normalized package version: %s\n" "${VERSION}"
printf "Latest built version: %s\n" "${CURRENT_VERSION}"

if [ "${CURRENT_VERSION}" = "${VERSION}" ]; then
    printf "No new version to release\n"
    exit 0
fi

export SHA256=$(
  gh release view "${LATEST_VERSION}" \
    --repo "${GH_REPO}" \
    --json assets \
    --jq '.assets[] | select(.name=="zen.linux-x86_64.tar.xz") | .digest' \
  | cut -d':' -f2
)

if [[ ! ${SHA256} =~ ^[a-f0-9]{64}$ ]]; then
    printf "Error: invalid sha256 received\n"
    exit 1
fi

envsubst '${SHA256} ${VERSION} ${_VERSION}' \
  < "${__dir}/.template" \
  > "${__dir}/template"

printf "zen-browser-bin template updated → %s\n" "${VERSION}"
