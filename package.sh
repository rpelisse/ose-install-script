#!/bin/bash

readonly FILES="node/node-install.sh
node/mcollective.node.tmpl
node/subscripts/add-bools.sh
node/subscripts/hostname-setup.sh
node/subscripts/kernel-tweaks.sh
node/subscripts/cgroups-pam.sh
node/subscripts/port-proxy.sh"

readonly VERSION=$(git tag | tail -1)
readonly ARCHIVE_NAME=$(basename $(pwd))-v${VERSION}.zip

echo -n "Packaging scripts in ${ARCHIVE_NAME}... "
rm -f "${ARCHIVE_NAME}"
zip "${ARCHIVE_NAME}" ${FILES} 2>&1 > /dev/null
echo 'Done.'
