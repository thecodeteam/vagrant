sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
yum install -y epel-release ntp git
yum update -y
systemctl enable ntpd
systemctl start ntpd
