#!/usr/bin/env bash

printf "Checking latest version\n"

__dir="$(dirname "${BASH_SOURCE[0]}")"

GH_REPO="BrowserWorks/waterfox"
_pkgname="waterfox"

LATEST_VERSION=$(gh release list --repo ${GH_REPO} --exclude-drafts --exclude-pre-releases --json name,tagName,isLatest --jq '.[] | select(.isLatest)|.tagName')
export VERSION=${LATEST_VERSION#"v"}
CURRENT_VERSION=$(grep -E '^version=' ${__dir}/template | cut -d= -f2)

printf "Latest version is: %s\nLatest built version is: %s\n" "${VERSION}" "${CURRENT_VERSION}"
[ "${CURRENT_VERSION}" = "${VERSION}" ] && printf "No new version to release\n" && exit 0

ARCHIVE="Linux_x86_64/${_pkgname}-${VERSION}.tar.bz2"
URL="https://cdn.waterfox.com/${_pkgname}/releases/${VERSION}/${ARCHIVE}"

printf "Downloading %s\n" "${URL}"

curl -L "${URL}" -o "${_pkgname}-${VERSION}.tar.bz2"

export SHA256=$(sha256sum "${_pkgname}-${VERSION}.tar.bz2" | cut -d ' ' -f1)

rm "${_pkgname}-${VERSION}.tar.bz2"

[[ ! ${SHA256} =~ ^[a-f0-9]+$ ]] && printf "got junk instead of sha256\n" && exit 1

envsubst '${SHA256} ${VERSION}' < "${__dir}/.template" > "${__dir}/template"

printf "waterfox-bin template updated\n"