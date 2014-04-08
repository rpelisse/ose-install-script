#/bin/bash

set -e

usage() {
  echo "$(basename ${0}) <node-fqdn> <node-public-ip> [path-to-script-config-file]"
  echo ''
  echo 'Both arguments are required. Public IP should already be registered in'
  echo 'DNS server, and associate with the FQDN.'
}

readonly NODE_HOSTNAME=${1}
readonly NODE_PUBLIC_IP=${2}
readonly SCRIPT_HOME=${SCRIPT_HOME:-$(pwd)}
readonly SCRIPT_CONFIG_FILE=${3:-"${SCRIPT_HOME}/${0%.sh}.conf"}

readonly OSE_VERSION=${OSE_VERSION:-'1.2'}

if [ -z ${NODE_HOSTNAME} ]; then
  echo "Missing node's FQDN:"
  usage
  exit 1
fi

if [ -z ${NODE_PUBLIC_IP} ]; then
  echo "Missing public IP associated to FQDN ${NODE_HOSTNAME}."
  usage
  exit 2
fi

if [ ! -e ${SCRIPT_CONFIG_FILE} ]; then
  echo "Missing script configuration file ${SCRIPT_CONFIG_FILE}, which definitions for:"
  echo 'readonly RHN_USERNAME=${RHN_USERNAME}'
  echo 'readonly RHN_PASSWORD=${RHN_PASSWORD}'
  echo 'readonly POOL_ID=${POOL_ID}'
  echo 'readonly BROKER=${BROKER}'
  echo 'readonly PSK_PASSWORD=${PSK_PASSWORD}'
  echo 'readonly MCO_PASSWORD=${MCO_PASSOWRD}'
  echo ''
  usage
  exit 3
else
  source "${SCRIPT_CONFIG_FILE}"
fi

checkEnvVar() {
  local name=${1}
  local value=${2}
  local config_file=${3}

  if [ -z "${value}" ]; then
    echo "Variable ${name} is not defined and is required - add it the script's configuration file:${config_file}"
    exit 4
  fi
}

checkEnvVar 'RHN_USERNAME' "${RHN_USERNAME}" "${SCRIPT_CONFIG_FILE}"
checkEnvVar 'RHN_PASSWORD' "${RHN_PASSWORD}" "${SCRIPT_CONFIG_FILE}"
checkEnvVar 'POOL_ID' "${POOL_ID}" "${SCRIPT_CONFIG_FILE}"
checkEnvVar 'BROKER' "${BROKER}" "${SCRIPT_CONFIG_FILE}"
checkEnvVar 'PSK_PASSWORD' "${PSK_PASSWORD}" "${SCRIPT_CONFIG_FILE}"
checkEnvVar 'MCO_PASSWORD' "${MCO_PASSOWRD}" "${SCRIPT_CONFIG_FILE}"

echo -n 'Setting locale to default ...'
export LANG=""
echo 'Done.'

isSELinuxEnabled() {

  if [ $(getenforce | grep -ie 'Permissive' -ie 'Enforcing' | wc -l) -eq 0 ]; then
    echo 'SE Linux appear to be disabled. Enable it and reboot:'
    echo ''
    exit 1
  fi
}

register_system() {
  local username=${1}
  local password=${2}

  set +e
  subscription-manager identity 2>&1 > /dev/null
  if [ ${?} -ne 0 ]; then
     subscription-manager register --username="${username}" --password="${password}"
  else
     echo "System is already registered to RHN, skipping registration."
  fi
  set -e
 }

attachSub() {
  local poolId=${1}
  set +e
  subscription-manager subscribe --pool="${poolId}"
  set -e
}

enableRepo() {
  local repoId=${1}

  subscription-manager repos --enable "${repoId}"
}

installRelease() {
    yum install -y 'openshift-enterprise-release'
}

yumValidator() {

 # First run will fix all issues, but returns != 0, so second run is for safety
 set +e
 oo-admin-yum-validator -o "${OSE_VERSION}" -r 'node' --fix-all
 set -e
 oo-admin-yum-validator -o "${OSE_VERSION}" -r 'node' --fix-all
}

isSELinuxEnabled

register_system "${RHN_USERNAME}" "${RHN_PASSWORD}"
attachSub "${POOL_ID}"
enableRepo 'rhel-server-ose-1.2-node-6-rpms'
enableRepo 'rhel-server-rhscl-6-rpms'
enableRepo 'jb-ews-2-for-rhel-6-server-rpms'

installRelease
yumValidator

${SCRIPT_HOME}/subscripts/hostname-setup.sh "${NODE_HOSTNAME}" "${NODE_PUBLIC_IP}" "${BROKER}"
${SCRIPT_HOME}/subscripts/hostname-setup.sh "${BROKER}" "${PSK_PASSWORD}" "${MCO_PASSWORD}" "${SCRIPT_HOME}/mcollective.node.tmpl"
${SCRIPT_HOME}/subscripts/node-if.sh
${SCRIPT_HOME}/subscripts/cgroups-pam.sh
${SCRIPT_HOME}/subscripts/kernel-tweaks.sh
${SCRIPT_HOME}/subscripts/port-proxy.sh
${SCRIPT_HOME}/subscripts/add-bools.sh

echo "Finished successfully, node ${NODE_HOSTNAME} is ready to be used."
