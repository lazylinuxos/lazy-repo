#!/usr/bin/env bash


printf "Checking latest version\n"

__dir="$(dirname "${BASH_SOURCE[0]}")"

GH_REPO="linuxmint/webapp-manager"

LATEST_VERSION=$(
  gh api repos/${GH_REPO}/tags \
  --jq '.[].name | select(startswith("master.") | not)' \
  | head -n1
)
export VERSION=${LATEST_VERSION#"v"}
CURRENT_VERSION=$(grep -E '^version=' ${__dir}/template | cut -d= -f2)

printf "Latest version is: %s\nLatest built version is: %s\n" "${VERSION}" "${CURRENT_VERSION}"
[ "${CURRENT_VERSION}" = "${VERSION}" ] && printf "No new version to release\n" && exit 0

# No preprepped checksum files, need to download the binary and calculate it myself
curl -L "https://github.com/${GH_REPO}/archive/refs/tags/${LATEST_VERSION}.tar.gz" -o "${VERSION}.tar.gz"
export SHA256=$(sha256sum ./${VERSION}.tar.gz | cut -d ' ' -f1 )
rm ./${VERSION}.tar.gz
[[ ! ${SHA256} =~ ^[a-z0-9]+$ ]] && printf "got junk instead of sha256\n" && exit 1

envsubst '${SHA256} ${VERSION}' < ${__dir}/.template > ${__dir}/template

printf "webapp-manager template updated\n"
