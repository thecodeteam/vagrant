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
storage     = data_bag_item('scaleio', 'storage')
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

execute 'first_mdm_login' do
  command "scli --login --username admin --password admin"
  action :nothing
  notifies :run, 'execute[set_mdm_password]', :immediately
  retries 5
  retry_delay 20
end

execute 'set_mdm_password' do
  command "scli --set_password --old_password admin --new_password #{system['password']}"
  action :nothing
end

execute 'mdm_login' do
  command "scli --mdm_ip #{primary_mdm} --login " +
    "--username admin --password #{system['password']} --approve_certificate"
  action :nothing
end

execute 'create_mdm_cluster' do
  command "scli --create_mdm_cluster --master_mdm_ip #{ips} " +
          "--master_mdm_management_ip #{mgmt_ip} " +
          "--master_mdm_name #{hostname} --accept_license"
  not_if { cluster_running? == true }
  only_if {node['packages']['EMC-ScaleIO-mdm']}
  notifies :run, 'execute[first_mdm_login]', :immediately
end

# Cluster configuration commands are performed by the primary MDM.
# SDS hosts must be added from MDM because `scli` is not included
# with SDS package.
if (node['packages']['EMC-ScaleIO-mdm'] && cluster_running?)

  ruby_block 'upgrade_cluster' do
    block do
      inferred_upgrade = get_inferred_upgrade()
      if (inferred_upgrade && inferred_upgrade[:mode] == '3_node')
        Chef::Log.debug("Starting 3_node upgrade")
        cmd = shell_out!(
          %Q[scli --switch_cluster_mode --cluster_mode 3_node \
             --add_slave_mdm_name #{inferred_upgrade[:nodes][:standbys][0][:name]} \
             --add_tb_name #{inferred_upgrade[:nodes][:tbs][0][:name]}
          ]
        ).run_command
        unless cmd.exitstatus == 0 or cmd.exitstatus == 2
          Chef::Application.fatal!('Failed to upgrade cluster')
        end
      else
        Chef::Log.debug("3_node upgrade skipped as not applicable: #{inferred_upgrade}")
      end
    end
    notifies :run, 'execute[mdm_login]', :before
  end

  ruby_block 'create_protection_domains' do
    block do
      pd_list = get_protection_domains
      Chef::Log.debug("Existing Protection Domains: #{pd_list}")
      if storage['protection_domains']
        storage['protection_domains'].each do |pd|
          create_protection_domain(pd['name']) unless pd_list.include?(pd['name'])
        end
      end
    end
    not_if { storage['protection_domains'] == nil }
    notifies :run, 'execute[mdm_login]', :before
  end

  storage['protection_domains'].each do |pd|

    ruby_block "create_storage_pools_#{pd['name']}" do
      block do
        pd['pools'].each do |pool_name|
          if pool_exists?(pd['name'], pool_name)
              Chef::Log.debug("Storage pool #{pd['name']}/#{pool_name} exists.")
          else
            create_storage_pool(pd['name'], pool_name)
          end
        end
      end
      not_if { pd['pools'] == nil }
    end

    ruby_block "create_sds_nodes_#{pd['name']}" do
      block do
        sds_list = get_sds_nodes
        pd['nodes'].each do |node|
          if ! sds_accessible?(node['ip'])
            Chef::Log.debug("SDS node #{node['name']} not operated on due to the service being unreachable from MDM primary")
            next
          end

          if sds_list.include?(node['name'])
            Chef::Log.debug("SDS node #{node['name']} exists.")
            next
          end

          create_sds_node(node['name'], node['ip'], pd['name'])
        end
      end
      not_if { pd['nodes'] == nil }
    end

    pd['nodes'].each do |node|

      ruby_block "create_sds_devices_#{pd['name']}_#{node['name']}" do
        block do
          configured_devices = get_sds_devices(node['name'])
          if configured_devices != nil
            node['pools'].each do |pool_name, devices|
              devices.each do |device|
                if configured_devices.include?(device)
                  Chef::Log.debug("Device #{node['name']}/#{device} is already configured.")
                  next
                end

                add_sds_device(node['name'], pool_name, device)
              end
            end
          end
        end
        not_if { node['pools'] == nil }
      end

    end

  end
end
