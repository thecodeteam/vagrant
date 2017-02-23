#
# Cookbook Name:: scaleio
# Recipe:: sdc
#

system  = data_bag_item('scaleio', 'system')
cluster = data_bag_item('scaleio', 'mdm_cluster')

PACKAGE="EMC-ScaleIO-sdc-#{system['version']}.#{system['platform']}"

include_recipe 'sysctl::default'

remote_file "/tmp/#{PACKAGE}.rpm" do
  source "http://130820808912778549.public.ecstestdrive.com/ScaleIO/#{PACKAGE}.rpm"
  action :create
end

ENV['MDM_IP'] = cluster['members'].select{ |m|
  m['role'] == 'manager'
}.map{ |m|
  m['ip']
}.join(',')

Chef::Log.debug("Installing SDC with MDM_IP=#{ENV['MDM_IP']}")

rpm_package PACKAGE do
  source "/tmp/#{PACKAGE}.rpm"
end
