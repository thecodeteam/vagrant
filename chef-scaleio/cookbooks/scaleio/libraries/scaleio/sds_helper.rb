module ScaleIO
  module SDSHelper
    include Chef::Mixin::ShellOut

    PD_REGEX = %r{^Protection Domain (?<id>[\d|\w]+) Name: (?<name>.+)$}

    SDS_REGEX = %r{^SDS ID: (?<id>[\d|\w]+) Name: (?<name>.+) State: (?<state>\w+), Joined IP: (?<ip>[\d|\.]+) Port: (?<port>\d+) Version: (?<version>[\d|\.]+)$}

    DEVICE_REGEX = %r{^\s+(?<index>\d+):\s.+Path:\s(?<path>[\/|\w|\d]+)\s+Original-path:\s(?<orig_path>[\/|\w|\d]+)\s+ID:\s(?<id>.+)$}x

    def create_protection_domain(pd)
      shell_out!(
        "scli --add_protection_domain --protection_domain_name #{pd}"
      ).run_command
      Chef::Log.debug("Added protection domain #{pd}")
    end

    def get_protection_domains
      query = shell_out!("scli --query_all_sds")
      query.run_command
      unless query.exitstatus == 0 or query.exitstatus == 2
        Chef::Application.fatal!("Failed to query SDS\n#{query.stderr}\n#{query.stdout}\n")
      end
      pd_matches = query.stdout.scan(PD_REGEX)
      pd_matches.map {|_id, name| name }
    end

    def pool_exists?(pd, pool)
      query = shell_out!(%Q[
        scli --query_storage_pool --protection_domain_name #{pd} --storage_pool_name #{pool}
      ], {returns: [0, 7, 8]})
      query.run_command
      if query.exitstatus == 0
        return true
      elsif query.exitstatus == 8 || query.exitstatus == 7
        return false
      else
        Chef::Log.debug("Failed to query storage pool #{pd}/#{pool}\n#{query.stderr}\n#{query.stdout}")
      end
    end

    def create_storage_pool(pd, pool)
      shell_out!(%Q[
        scli --add_storage_pool --protection_domain_name #{pd} --storage_pool_name #{pool}
      ]).run_command
    end

    def create_sds_node(name, ip, pd)
      shell_out(%Q[
        scli --add_sds --sds_name #{name} --sds_ip #{ip} --protection_domain_name #{pd} --i_am_sure
      ]).run_command
    end

    def sds_accessible?(host)
      port_is_open?(host, 7072)
    end

    def get_sds_nodes
      query = shell_out!("scli --query_all_sds")
      query.run_command
      unless query.exitstatus == 0 or query.exitstatus == 2
        Chef::Application.fatal!("Failed to query SDS\n#{query.stderr}\n#{query.stdout}\n")
      end
      sds_matches = query.stdout.scan(SDS_REGEX)
      sds_matches.map {|_id, name, _state, _ip, _port, _version| name }
    end

    def get_sds_devices(sds_name)
      query = shell_out!("scli --query_sds --sds_name #{sds_name}", returns: [0,7])
      query.run_command
      if query.exitstatus == 7
        Chef::Log.debug("Failed to query SDS. Must not be ready: \n#{query.stderr}\n#{query.stdout}\n")
        return nil
      end
      matches = query.stdout.scan(DEVICE_REGEX)
      # Name: N/A  Path: /dev/sdb  Original-path: /dev/sdb  ID: f64a2b4b00000000
      matches.map{ |_index, path, _orig_path, _id| path }.compact
    end

    def add_sds_device(sds_name, pool_name, device)
      cmd = shell_out!(%Q[
        scli --add_sds_device --sds_name #{sds_name} \
          --device_path #{device} --storage_pool_name #{pool_name}
        ],
        returns: [0, 7]
      )
      cmd.run_command
      if cmd.exitstatus == 7
        Chef::Log.info("Failed to add devices: #{cmd.stderr}\n#{cmd.stdout}\n")
      end
    end

    private

    def port_is_open?(host, port)
      begin
        Timeout::timeout(1) do
          begin
            s = TCPSocket.new(host, port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return false
          end
        end
      rescue Timeout::Error
      end
      false
    end

  end
end

Chef::Recipe.include(ScaleIO::SDSHelper)
