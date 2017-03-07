#
# Cookbook Name:: sysctl
# Attributes:: default
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
default['sysctl']['params'] = {}
default['sysctl']['allow_sysctl_conf'] = false
default['sysctl']['conf_file'] = '/etc/sysctl.conf'
default['sysctl']['conf_dir'] = nil

if platform_family?('freebsd')
  default['sysctl']['allow_sysctl_conf'] = true
  default['sysctl']['conf_file'] = '/etc/sysctl.conf.local'
end

if platform_family?('arch', 'debian', 'rhel', 'fedora')
  default['sysctl']['conf_dir'] = '/etc/sysctl.d'
  default['sysctl']['conf_file'] = File.join(node['sysctl']['conf_dir'], '/99-chef-attributes.conf')
end

if platform_family?('suse')
  if node['platform_version'].to_f < 12.0
    default['sysctl']['allow_sysctl_conf'] = true
    default['sysctl']['conf_file'] = '/etc/sysctl.conf'
  else
    default['sysctl']['conf_dir'] = '/etc/sysctl.d'
    default['sysctl']['conf_file'] = File.join(node['sysctl']['conf_dir'], '/99-chef-attributes.conf')
  end
end
