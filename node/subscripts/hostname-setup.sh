#!/bin/bash

readonly NODE_HOSTNAME=${1}
readonly NODE_PUBLIC_IP=${2}
readonly BROKER=${3}
readonly DOMAIN=${4}

if [ -z "${NODE_HOSTNAME}" ]; then
  echo "Missing required argument: node hostname (fqdn)"
  echo ''
  exit 1
fi

if [ -z "${NODE_PUBLIC_IP}" ]; then
  echo 'Missing required argument: node public IP'
  echo ''
  exit 2
fi

sed -i /etc/sysconfig/network -e "s/^\(HOSTNAME=\).*$/\1${NODE_HOSTNAME}/"
hostname "${NODE_HOSTNAME}"

readonly BROKER_IP=$(dig "${BROKER}" | grep "^${BROKER}" | cut -f1 | sed -e 's/\.$//')

if [ $(grep -e "${BROKER_IP}" /etc/resolv.conf | wc -l ) -eq 0 ]; then
  new_ect_resolv_file=$(mktemp)
  echo "search ${DOMAIN}" >> "${new_ect_resolv_file}"
  echo "nameserver ${BROKER_IP}" >> "${new_ect_resolv_file}"
  echo '' >> "${new_ect_resolv_file}"
  cat /etc/resolv.conf >> "${new_ect_resolv_file}"
  mv "${new_ect_resolv_file}" /etc/resolv.conf
fi
