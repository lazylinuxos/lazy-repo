#!/usr/bin/env bash
set -euo pipefail

printf "Checking latest version\n"

__dir="$(dirname "${BASH_SOURCE[0]}")"

PKG_NAME="konform-browser"
API="https://codeberg.org/api/v1/repos/${PKG_NAME}/source/releases"

# get latest release tag
LATEST_VERSION=$(curl -s "${API}" | jq -r '.[0].tag_name')

export VERSION=${LATEST_VERSION#"v"}
CURRENT_VERSION=$(grep -E '^version=' "${__dir}/template" | cut -d= -f2)

printf "Latest version is: %s\nLatest built version is: %s\n" "${VERSION}" "${CURRENT_VERSION}"

if [[ "${CURRENT_VERSION}" == "${VERSION}" ]]; then
    printf "No new version to release\n"
    exit 0
fi

export UPSTREAM_VERSION="${LATEST_VERSION%.*}-${LATEST_VERSION##*.}"
RELEASE_URL="https://codeberg.org/api/packages/${PKG_NAME}/generic/${PKG_NAME}/${UPSTREAM_VERSION}/${PKG_NAME}-${UPSTREAM_VERSION}-linux-x86_64-deb.deb"

printf "Downloading %s\n" "${RELEASE_URL}"

curl -L "${RELEASE_URL}" -o "${VERSION}.tar.gz"

export SHA256=$(sha256sum "${VERSION}.tar.gz" | cut -d' ' -f1)

rm "${VERSION}.tar.gz"

[[ ! ${SHA256} =~ ^[a-z0-9]+$ ]] && printf "got junk instead of sha256\n" && exit 1

envsubst '${SHA256} ${VERSION} ${UPSTREAM_VERSION}' < "${__dir}/.template" > "${__dir}/template"

printf "konform-browser-bin template updated\n"