#!/usr/bin/env bash
set -euo pipefail

printf "Checking latest version\n"

__dir="$(dirname "${BASH_SOURCE[0]}")"

GL_PROJECT="World%2Fpika-backup"

API="https://gitlab.gnome.org/api/v4/projects/${GL_PROJECT}/repository/tags?per_page=20"

LATEST_TAG=$(curl -s "${API}" | jq -r '[.[] | select(.name | test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))][0].name')
export VERSION=${LATEST_TAG#v}

CURRENT_VERSION=$(grep -E '^version=' "${__dir}/template" | cut -d= -f2)

printf "Latest version is: %s\nLatest built version is: %s\n" "${VERSION}" "${CURRENT_VERSION}"

if [[ "${CURRENT_VERSION}" = "${VERSION}" ]]; then
    printf "No new version to release\n"
    exit 0
fi

ARCHIVE="pika-backup-${VERSION}.tar.gz"
URL="https://gitlab.gnome.org/World/pika-backup/-/archive/${LATEST_TAG}/${ARCHIVE}"

printf "Downloading %s\n" "${URL}"

curl -L "${URL}" -o "${ARCHIVE}"

export SHA256=$(sha256sum "${ARCHIVE}" | cut -d ' ' -f1)

rm "${ARCHIVE}"

[[ ! ${SHA256} =~ ^[a-z0-9]+$ ]] && printf "got junk instead of sha256\n" && exit 1

envsubst '${SHA256} ${VERSION}' < "${__dir}/.template" > "${__dir}/template"

printf "pika-backup template updated\n"