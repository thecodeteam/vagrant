sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
yum install -y epel-release ntp git
systemctl enable ntpd
systemctl start ntpd
