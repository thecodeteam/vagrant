#
# Cookbook Name:: scaleio
# Recipe:: default
#

system  = data_bag_item('scaleio', 'system')
PACKAGE="EMC-ScaleIO-lia-#{system['version']}.#{system['platform']}"

remote_file "/tmp/#{PACKAGE}.rpm" do
  source "http://130820808912778549.public.ecstestdrive.com/ScaleIO/#{PACKAGE}.rpm"
  action :create
end

ENV['TOKEN'] = system['password']

rpm_package PACKAGE do
  source "/tmp/#{PACKAGE}.rpm"
end
