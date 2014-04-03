#!/bin/bash

usage() {
  echo "$(basename ${0}) <USERNAME> <PASSWORD>"
  echo ''
}

readonly USERNAME=${1}
readonly PASSWORD=${2}

if [ -z ${USERNAME} ]; then
  echo "No USERNAME provided"
  usage
  exit 1
fi

if [ -z ${PASSWORD} ]; then
  echo "No PASSWORD provided"
  usage
  exit 1
fi

htpasswd -b /etc/openshift/htpasswd "${USERNAME}" "${PASSWORD}"
service openshift-console stop
service openshift-broker restart
echo "Waiting for Broker to be really 'up'..."
sleep 60
service openshift-console start
oo-admin-broker-cache --clear --console
sleep 10
echo "OK, good to go"
