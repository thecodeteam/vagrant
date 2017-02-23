#
# Cookbook Name:: sysctl
# Recipe:: default
#
# Copyright 2011, Fewbytes Technologies LTD
# Copyright 2012, Chris Roberts <chrisroberts.code@gmail.com>
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

include_recipe 'sysctl::service'

directory 'Sysctl config directory' do
  path node['sysctl']['conf_dir']
  owner 'root'
  group 'root'
  mode 0o755
  action :create
  only_if { !node['sysctl']['conf_dir'].nil? }
end

sysctl_config_file = Sysctl.config_file(node)

if sysctl_config_file
  # If default sysctl.params attributes are not set, set them at recipe compile time
  # to the values output by the last run. This allows the LWRPs to act idempotently
  if File.exist?(sysctl_config_file)
    File.read(sysctl_config_file).lines.each do |l|
      next unless l =~ /^[\w\.]+?=/
      key, val = l.chomp.split('=')
      key_path = key.split('.')
      location = key_path.slice(0, key_path.size - 1).reduce(node.default['sysctl']['params']) do |m, o|
        m[o] ||= {}
        m[o]
      end
      location[key_path.last] ||= val.to_s
    end
  end

  # this is called by the sysctl_param lwrp to trigger template creation
  ruby_block 'save-sysctl-params' do
    action :nothing
    block do
    end
    notifies :create, "template[#{sysctl_config_file}]", :delayed
  end

  # this is called by the sysctl::apply recipe to trigger template creation
  ruby_block 'apply-sysctl-params' do
    action :nothing
    block do
    end
    notifies :create, "template[#{sysctl_config_file}]", :immediately
  end

  # this needs to have an action in case node.sysctl.params has changed
  # and also needs to be called for persistence on lwrp changes via the
  # ruby_block
  template sysctl_config_file do
    action :nothing
    source 'sysctl.conf.erb'
    mode '0644'
    notifies :restart, 'service[procps]', :immediately
  end
end
