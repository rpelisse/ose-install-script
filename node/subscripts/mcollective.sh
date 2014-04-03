#/bin/bash

set -e

usage() {
  echo "$(basename ${0}) <broker-fqdn> <psk-password> <mco-password> <path-to-mco-config-template>"
  echo ''
}

readonly BROKER=${1}
readonly PSK_PASSWORD=${2}
readonly PSK_PASSWORD=${3}
readonly MCO_CONFIG_TEMPLATE={4}

if [ -z ${BROKER} ]; then
  echo "Missing broker's FQDN:"
  usage
  exit 1
fi

if [ -z ${PSK_PASSWORD} ]; then
  echo "Missing psk password."
  usage
  exit 2
fi

if [ -z ${MCO_PASSWORD} ]; then
  echo "Missing mcollective password."
  usage
  exit 3
fi

if [ -z ${MCO_CONFIG_TEMPLATE} ]; then
  echo "Missing path to mcollective server config template."
  usage
  exit 4
else
  if [ ! -e ${MCO_CONFIG_TEMPLATE} ]; then
    echo "The provided MCollective server config template does not exist: ${MCO_CONFIG_TEMPLATE}"
    exit 5
  fi
fi

readonly PATH_TO_MCO_SERVER_CFG=${PATH_TO_MCO_SERVER_CFG:-'/etc/mcollective/server.cfg'}

yum install -y 'openshift-origin-msg-node-mcollective'

echo -n "Updating MCollective configuration to connect to ${BROKER}... "
cp '/etc/mcollective/server.cfg' '/etc/mcollective/server.cfg.bck'
sed ${MCO_CONFIG_TEMPLATE} \
    -e "s/BROKER/${BROKER}/g" \
    -e "s/PSK_PASSWORD/${PSK_PASSWORD}/" \
    -e "s/PASSWORD/${MCO_PASSWORD}/g" > "${PATH_TO_MCO_SERVER_CFG}"
echo 'Done.'

if [ ! -e ${PATH_TO_MCO_SERVER_CFG} ]; then
  echo "ERROR, file was not generated (is empty) aborting."
  exit 6
fi

chkconfig mcollective 'on'
service mcollective 'restart'
