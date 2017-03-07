#
# Cookbook Name:: sysctl
# Recipe:: service
#
# Copyright 2013-2014, OneHealth Solutions, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

template '/etc/rc.d/init.d/procps' do
  source 'procps.init-rhel.erb'
  mode '0755'
  only_if { platform_family?('rhel', 'fedora', 'pld') }
end

service 'procps' do # rubocop:disable Metrics/BlockLength
  supports :restart => true, :reload => true, :status => false
  case node['platform']
  when 'freebsd'
    service_name 'sysctl'
  when 'arch', 'exherbo'
    service_name 'systemd-sysctl'
    provider Chef::Provider::Service::Systemd
  when 'centos', 'redhat', 'scientific'
    if node['platform_version'].to_f >= 7.0
      service_name 'systemd-sysctl'
      provider Chef::Provider::Service::Systemd
    end
  when 'fedora'
    if node['platform_version'].to_f >= 18
      service_name 'systemd-sysctl'
      provider Chef::Provider::Service::Systemd
    end
  when 'ubuntu'
    if node['platform_version'].to_f >= 9.10 && node['platform_version'].to_f < 15.04
      service_name 'procps-instance' if node['platform_version'].to_f >= 14.10
      provider Chef::Provider::Service::Upstart
    elsif node['platform_version'].to_f >= 15.04
      service_name 'systemd-sysctl'
      provider Chef::Provider::Service::Init::Systemd
    end
  when 'suse'
    if node['platform_version'].to_f < 12.0
      supports :restart => false, :reload => false, :status => true
      service_name 'boot.sysctl'
    elsif node['platform_version'].to_f >= 12.0
      service_name 'systemd-sysctl'
      provider Chef::Provider::Service::Systemd
    end
  end
  action :enable
end
