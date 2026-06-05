#!/usr/bin/env bash

set -euo pipefail

printf "Checking latest version\n"

__dir="$(dirname "${BASH_SOURCE[0]}")"

REPO_URL="https://git.dinox.im/api/v1/repos/dinoxim/dinox"

LATEST_VERSION=$(
	curl -fsSL "${REPO_URL}/tags" \
		| jq -r '.[0].name'
)

export VERSION="${LATEST_VERSION#v}"
CURRENT_VERSION=$(grep -E '^version=' "${__dir}/template" | cut -d= -f2)

printf "Latest version is: %s\nLatest built version is: %s\n" \
	"${VERSION}" "${CURRENT_VERSION}"

[ "${CURRENT_VERSION}" = "${VERSION}" ] && \
	printf "No new version to release\n" && exit 0

TARBALL_URL="https://git.dinox.im/dinoxim/dinox/archive/v${VERSION}.tar.gz"

curl -fsSL "${TARBALL_URL}" -o "${VERSION}.tar.gz"

export SHA256=$(sha256sum "${VERSION}.tar.gz" | cut -d' ' -f1)

rm -f "${VERSION}.tar.gz"

[[ ! ${SHA256} =~ ^[a-f0-9]{64}$ ]] && \
	printf "got junk instead of sha256\n" && exit 1

envsubst '${SHA256} ${VERSION}' < "${__dir}/.template" > "${__dir}/template"

printf "dinox template updated\n"