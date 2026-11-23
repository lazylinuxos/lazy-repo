#!/usr/bin/env bash

set -euo pipefail

printf "Checking latest version\n"

__dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

FORGEJO_URL="https://justaguy.dev"
REPO="drew/ghee"
REPO_URL="${FORGEJO_URL}/${REPO}"
API_URL="${FORGEJO_URL}/api/v1/repos/${REPO}/tags"

# Fetch tags from Forgejo API
LATEST_VERSION=$(
    curl -fsSL "${API_URL}?limit=100" |
        jq -r '
            [
                .[] |
                .name |
                select(test("^v?[0-9]+\\.[0-9]+\\.[0-9]+$"))
            ] |
            sort_by(
                sub("^v"; "") |
                split(".") |
                map(tonumber)
            ) |
            last // empty
        '
)

if [[ -z "${LATEST_VERSION}" ]]; then
    printf "ERROR: No valid version tags found\n" >&2
    exit 1
fi

VERSION="${LATEST_VERSION#v}"
CURRENT_VERSION=$(
    sed -n 's/^version=//p' "${__dir}/template" |
        head -n 1
)

printf "Latest version is: %s\n" "${VERSION}"
printf "Latest built version is: %s\n" "${CURRENT_VERSION}"

if [[ "${CURRENT_VERSION}" == "${VERSION}" ]]; then
    printf "No new version to release\n"
    exit 0
fi

TARBALL_URL="${REPO_URL}/archive/${LATEST_VERSION}.tar.gz"

TARBALL=$(mktemp)
trap 'rm -f "${TARBALL}"' EXIT

curl -fsSL "${TARBALL_URL}" -o "${TARBALL}"

SHA256=$(sha256sum "${TARBALL}" | cut -d' ' -f1)

if [[ ! "${SHA256}" =~ ^[a-f0-9]{64}$ ]]; then
    printf "ERROR: Invalid SHA256 checksum\n" >&2
    exit 1
fi

export VERSION SHA256

envsubst '${SHA256} ${VERSION}' \
    < "${__dir}/.template" \
    > "${__dir}/template"

printf "ghee template updated to %s\n" "${VERSION}"
