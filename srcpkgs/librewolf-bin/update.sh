#!/usr/bin/env bash
set -euo pipefail

printf "Checking latest version\n"

__dir="$(dirname "${BASH_SOURCE[0]}")"

GL_PROJECT_ID=44042130
PKGNAME="librewolf"

API="https://gitlab.com/api/v4/projects/${GL_PROJECT_ID}/packages?package_name=${PKGNAME}&package_type=generic&order_by=created_at&sort=desc&per_page=1"
LATEST_PKG_VERSION=$(curl -s "${API}" | jq -r '.[0].version')

export VERSION=${LATEST_PKG_VERSION%-*}
export _VERSION=${LATEST_PKG_VERSION}

CURRENT_VERSION=$(grep -E '^version=' "${__dir}/template" | cut -d= -f2)

printf "Latest version is: %s\nLatest built version is: %s\n" "${VERSION}" "${CURRENT_VERSION}"

if [[ "${CURRENT_VERSION}" = "${VERSION}" ]]; then
    printf "No new version to release\n"
    exit 0
fi

FILE="${PKGNAME}-${_VERSION}-linux-x86_64-deb.deb"

URL="https://gitlab.com/api/v4/projects/${GL_PROJECT_ID}/packages/generic/${PKGNAME}/${_VERSION}/${FILE}"

printf "Downloading %s\n" "${URL}"

curl -L "${URL}" -o "${FILE}"

export SHA256=$(sha256sum "${FILE}" | cut -d ' ' -f1)

rm "${FILE}"

[[ ! ${SHA256} =~ ^[a-z0-9]+$ ]] && printf "got junk instead of sha256\n" && exit 1

envsubst '${SHA256} ${VERSION} ${_VERSION}' < "${__dir}/.template" > "${__dir}/template"

printf "librewolf-bin template updated\n"