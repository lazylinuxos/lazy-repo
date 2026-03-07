#!/usr/bin/env bash

printf "Checking latest version\n"

__dir="$(dirname "${BASH_SOURCE[0]}")"

GH_REPO="processone/fluux-messenger"

LATEST_VERSION=$(gh release list --repo ${GH_REPO} --exclude-drafts --exclude-pre-releases --json name,tagName,isLatest --jq '.[] | select(.isLatest)|.tagName')
export VERSION=${LATEST_VERSION#"v"}
CURRENT_VERSION=$(grep -E '^version=' ${__dir}/template | cut -d= -f2)

printf "Latest version is: %s\nLatest built version is: %s\n" "${VERSION}" "${CURRENT_VERSION}"
[ "${CURRENT_VERSION}" = "${VERSION}" ] && printf "No new version to release\n" && exit 0

# No preprepped checksum files, need to download the binary and calculate it myself
ASSET="Fluux-Messenger_${VERSION}_Linux_x64.rpm"
export SHA256=$(gh release view "$LATEST_VERSION" \
  --repo "$GH_REPO" \
  --json assets \
  --jq ".assets[] | select(.name == \"$ASSET\") | .digest | sub(\"^sha256:\"; \"\")" )

[[ ! ${SHA256} =~ ^[a-z0-9]+$ ]] && printf "got junk instead of sha256\n" && exit 1

envsubst '${SHA256} ${VERSION}' < ${__dir}/.template > ${__dir}/template

printf "fluux-messenger-bin template updated\n"