#/bin/bash
set -e

readonly PAM_SSHD_CONFIG_FILE='/etc/pam.d/sshd'

sed -i -e 's|pam_selinux|pam_openshift|g' "${PAM_SSHD_CONFIG_FILE}"

for f in "runuser" "runuser-l" "sshd" "su" "system-auth-ac"
do
	t="/etc/pam.d/$f"
	if ! grep -q "pam_namespace.so" "$t"
	then
		printf 'session\t\t[default=1 success=ignore]\tpam_succeed_if.so quiet shell = /usr/bin/oo-trap-user\n' >> "$t"
		printf 'session\t\trequired\tpam_namespace.so no_unmount_on_close\n' >> "$t"
	fi
done

printf '/tmp $HOME/.tmp/ user:iscript=/usr/sbin/oo-namespace-init root,adm\n' > /etc/security/namespace.d/tmp.conf
printf '/dev/shm tmpfs tmpfs:mntopts=size=5M:iscript=/usr/sbin/oo-namespace-init root,adm\n' > /etc/security/namespace.d/shm.conf

for f in "runuser" "runuser-l" "sshd" "system-auth-ac";
do t="/etc/pam.d/$f";
  if ! grep -q "pam_cgroup" "$t"; then
    printf 'session\t\toptional\tpam_cgroup.so\n' >> "$t";
  fi;
done;

cp -vf /opt/rh/ruby193/root/usr/share/gems/doc/openshift-origin-node-*/cgconfig.conf /etc/cgconfig.conf
restorecon -rv /etc/cgconfig.conf
mkdir -p /cgroup
restorecon -rv /cgroup

chkconfig cgconfig on
chkconfig cgred on
chkconfig openshift-cgroups on
service cgconfig restart
service cgred restart
service openshift-cgroups restart
