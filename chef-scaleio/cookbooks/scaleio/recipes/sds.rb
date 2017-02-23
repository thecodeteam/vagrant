#
# Cookbook Name:: scaleio
# Recipe:: sds
#

system  = data_bag_item('scaleio', 'system')

PACKAGE="EMC-ScaleIO-sds-#{system['version']}.#{system['platform']}"

include_recipe 'sysctl::default'

remote_file "/tmp/#{PACKAGE}.rpm" do
  source "http://130820808912778549.public.ecstestdrive.com/ScaleIO/#{PACKAGE}.rpm"
  action :create
end

rpm_package PACKAGE do
  source "/tmp/#{PACKAGE}.rpm"
end
