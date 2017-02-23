#
# Cookbook Name:: scaleio
# Recipe:: mdm
#

Chef::Recipe.include Chef::Mixin::ShellOut

Chef::Resource::Execute.include(ScaleIO::MDMHelper)
Chef::Resource::RubyBlock.include(ScaleIO::MDMHelper)
Chef::Resource::RubyBlock.include(ScaleIO::SDSHelper)

system      = data_bag_item('scaleio', 'system')
mdm_cluster = data_bag_item('scaleio', 'mdm_cluster')
ips         = find_addresses_in_networks(node, system['networks']).join(',')
mgmt_ip     = find_address_in_network(node, system['mgmt_network'])
hostname    = node['hostname']
membership  = mdm_cluster['members'].find{|n| n['hostname'] == node['hostname']}
primary_mdm = mdm_cluster['members'].find{|n| n['primary'] == true }['ip']
role        = membership['role']

PACKAGE="EMC-ScaleIO-mdm-#{system['version']}.#{system['platform']}"

include_recipe 'sysctl::default'

sysctl_param 'kernel.shmmax' do
  value 209715200
end

remote_file "/tmp/#{PACKAGE}.rpm" do
  source "http://130820808912778549.public.ecstestdrive.com/ScaleIO/#{PACKAGE}.rpm"
  action :create
end

ENV['MDM_ROLE_IS_MANAGER'] = role == "manager" ? "1" : "0"

rpm_package PACKAGE do
  source "/tmp/#{PACKAGE}.rpm"
end

execute 'mdm_login' do
  command "scli --mdm_ip #{primary_mdm} --login " +
    "--username admin --password #{system['password']} --approve_certificate"
  action :nothing
end

execute 'join_mdm_cluster' do
  command "scli --mdm_ip #{primary_mdm} --add_standby_mdm --new_mdm_ip #{ips} " +
          "--mdm_role #{role} --new_mdm_management_ip #{mgmt_ip} " +
          "--new_mdm_name #{hostname} --approve_certificate"
  returns [0, 7]
  notifies :run, 'execute[mdm_login]', :before
  only_if { primary_accessible?(primary_mdm) == true && node['packages']['EMC-ScaleIO-mdm'] != nil }
end
