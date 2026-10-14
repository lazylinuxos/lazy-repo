#!/usr/bin/env bash
set -euo pipefail

printf "Checking latest version of kaidan\n"

__dir="$(dirname "${BASH_SOURCE[0]}")"

REPO_URL="https://github.com/KDE/kaidan.git"

# Get latest tag from remote
LATEST_VERSION=$(
    git ls-remote --tags --refs "$REPO_URL" |
        awk -F/ '{print $3}' |
        grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' |
        sort -V |
        tail -n1
)

[[ -n "$LATEST_VERSION" ]] || {
    printf "Failed to determine latest version\n" >&2
    exit 1
}

VERSION=${LATEST_VERSION#"v"}
CURRENT_VERSION=$(grep -E '^version=' "${__dir}/template" | cut -d= -f2)

printf "Latest version is: %s\nCurrent template version is: %s\n" "${VERSION}" "${CURRENT_VERSION}"
[ "${CURRENT_VERSION}" = "${VERSION}" ] && printf "No new version to release\n" && exit 0

# Download source tarball to calculate checksum
TARBALL_URL="https://invent.kde.org/network/kaidan/-/archive/v${VERSION}/kaidan-v${VERSION}.tar.gz"
TEMP_FILE="${VERSION}.tar.gz"
curl -L -o "${TEMP_FILE}" "${TARBALL_URL}"

# Compute SHA256
SHA256=$(sha256sum "${TEMP_FILE}" | cut -d ' ' -f1)
rm -f "${TEMP_FILE}"

[[ ! ${SHA256} =~ ^[a-z0-9]+$ ]] && printf "got junk instead of sha256\n" && exit 1

# Update template using envsubst
export SHA256 VERSION
envsubst '${SHA256} ${VERSION}' < "${__dir}/.template" > "${__dir}/template"

printf "kaidan template updated to version %s\n" "${VERSION}"
