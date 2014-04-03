#!/bin/bash

readonly DOMAIN=${DOMAIN}

if [ -z ${DOMAIN} ]; then
  echo "The env var DOMAIN is empty - please provide a proper DNS domain name."
  exit 1
fi

readonly KEYFILE=${KEYFILE:-"/var/named/${DOMAIN}.key"}
readonly DNS_KEYGEN=${DNS_KEYGEN:-'dnssec-keygen'}
readonly RNDC_CONFGEN=${RNDC_CONFGEN:-'rndc-confgen'}
readonly YUM_CMD=${YUM_CMD:-'yum'}

readonly RPM_PACKAGES=${RPM_PACKAGES:-'bind bind-utils'}

readonly BIND_USERNAME=${BIND_USERNAME:-'named'}
readonly BIND_FOLDER=${BIND_FOLDER:-'/var/named'}
readonly AUTHORATIVE_DNS_SERVER=${AUTHORATIVE_DNS_SERVER:-$(cat /etc/resolv.conf  | grep nameserver | head -1 | cut -f2 -d\ )}

check_dependencies() {
    local dependencies="${@}"

    set +e
    dependencies_missing=0
    for dependency in ${dependencies}
    do
      which ${dependency} 2> /dev/null > /dev/null
      status="${?}"
      if [ ${status} -ne 0 ] ; then
        echo "This script requires the command ${dependency} - please install it."
        dependencies_missing="${status}"
      fi
    done
    set -e
    if [ "${dependencies_missing}" -ne 0 ]; then
      exit ${dependencies_missing}
    fi
}

yum_install() {
  local packages="${@}"

  ${YUM_CMD} install ${packages}
  if [ "${?}" -ne 0 ]; then
    echo "Installation of packages ${packages} failed - abort installation."
  fi
}

set -e
yum_install ${RPM_PACKAGES}
check_dependencies "${DNS_KEYGEN}" "${RNDC_CONFGEN}" "${YUM_CMD}"
echo -n "Generating DNSSEC Key to allow dynamic update to the bind server... "
mkdir -p "${BIND_FOLDER}"
cd "${BIND_FOLDER}" > /dev/null
"${DNS_KEYGEN}" -a HMAC-MD5 -b 512 -n USER -r /dev/urandom ${DOMAIN} 2>&1 > /dev/null
readonly KEY="$(grep Key: K${DOMAIN}*.private | cut -d' ' -f2)"
cd - > /dev/null

readonly RNDC_KEY_FILE=${RNDC_KEY_FILE:-'/etc/rndc.key'}
"${RNDC_CONFGEN}" -a -r /dev/urandom 2>&1 > /dev/null
chown ${BIND_USERNAME}:${BIND_USERNAME} "${RNDC_KEY_FILE}" 2>&1 > /dev/null
chmod 640 "${RNDC_KEY_FILE}"
if [ -n ${DEBUG} ]; then
  echo ${KEY}
fi

echo -n "Forward unknown request to authoratize DNS server... "
readonly FORWARD_CONF_FILE=${FORWARD_CONF_FILE:-"${BIND_FOLDER}/forwarders.conf"}
echo 'forwarders { '${AUTHORATIVE_DNS_SERVER}'; };' > "${FORWARD_CONF_FILE}"
chmod '755' "${FORWARD_CONF_FILE}" 2>&1 > /dev/null
echo 'Done.'


echo -n "Set up initial zone configuration for domain ${DOMAIN}... "
readonly DOMAIN_ZONE_CONF_FILE=${DOMAIN_ZONE_CONF_FILE:-"/var/named/dynamic/${DOMAIN}.db"}
mkdir -p $(dirname "${DOMAIN_ZONE_CONF_FILE}")
echo '$ORIGIN .' >> "${DOMAIN_ZONE_CONF_FILE}"
echo '$TTL 1 ; 1 second for testing purposes' >> "${DOMAIN_ZONE_CONF_FILE}"
echo "${DOMAIN} IN SOA ns1.${DOMAIN} hostmaster.${DOMAIN}. (" >> "${DOMAIN_ZONE_CONF_FILE}"
echo '          2013040101; serial' >> "${DOMAIN_ZONE_CONF_FILE}"
echo '          60; refresh (1 minute)' >> "${DOMAIN_ZONE_CONF_FILE}"
echo '          15; retry (15 seconds)' >> "${DOMAIN_ZONE_CONF_FILE}"
echo '          1800; expire (30 minutes)' >> "${DOMAIN_ZONE_CONF_FILE}"
echo '          10; minimum (10 seconds)' >> "${DOMAIN_ZONE_CONF_FILE}"
echo '          )' >> "${DOMAIN_ZONE_CONF_FILE}"
echo "   IN NS ns1.${DOMAIN}." >> "${DOMAIN_ZONE_CONF_FILE}"
echo "   IN MX 10 mail.${DOMAIN}." >> "${DOMAIN_ZONE_CONF_FILE}"
echo "\$ORIGIN ${DOMAIN}." >> "${DOMAIN_ZONE_CONF_FILE}"
echo "ns1 A 127.0.0.1" >> "${DOMAIN_ZONE_CONF_FILE}"
echo 'Done.'

echo -n "Set up domain DNS key... "
readonly DNSSEC_KEY_FILE=${DNSSEC_KEY_FILE:-"/var/named/${DOMAIN}.key"}
echo "key \"${DOMAIN}\" {" >> "${DNSSEC_KEY_FILE}"
echo "    algorithm HMAC-MD5;" >> "${DNSSEC_KEY_FILE}"
echo "    secret \"${KEY}\";" >> "${DNSSEC_KEY_FILE}"
echo "};" >> "${DNSSEC_KEY_FILE}"
echo 'Done'

echo -n "Ensures all files in ${BIND_FOLDER} belongs to user ${BIND_USERNAME}... "
chown -Rv ${BIND_USERNAME}:${BIND_USERNAME} "${BIND_FOLDER}" 2>&1 > /dev/null # just to be on the safe side of the road...
echo 'Done.'

echo -n "Deploy Bind configuration for local OSE broker... "
readonly BIND_CONF=${BIND_CONF:-'/etc/named.conf'}
cp "${BIND_CONF}" "${BIND_CONF}.bck"
sed -e "s/FORWARDERS_CONF_FILE/${FORWARD_CONF_FILE}/" \
    -e "s/RNDC_KEY_FILE/${RNDC_KEY_FILE}/"
    -e "s/DNSSEC_KEY_FILE/${DNSSEC_KEY_FILE}/" \
    -e "s/DOMAIN/${DOMAIN}/g" > "${BIND_CONF}"
echo 'Done.'
restorecon /etc/rndc.* /etc/named.*

echo 'Bind installation is over.'
