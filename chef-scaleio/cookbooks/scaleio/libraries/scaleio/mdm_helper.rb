module ScaleIO
  module MDMHelper
    include Chef::Mixin::ShellOut

    NODE_STATUS_REGEX = %r{
    \s+Name:\s(?<master_name>\w+),
    \sID:\s(?<master_id>[\d|\w]+)
    (,\s(?<role>[\w|\s]+))*\n
    \s+IPs:\s(?<ips>[\d|\.|,]+),
    \s(Management\sIPs:\s(?<mgmt_ip>[\d|\.]+),\s)*
    Port:\s(?<port>\d+)
    (\n\s+Version:\s(?<version>[\d|\.]+))*
    }x

    CLUSTER_STATUS_REGEX = %r{
    ^Cluster:\n
    \s+Mode:\s(?<mode>[\w|\d|_]+),\sState:\s(?<state>\w+),
    \sActive:\s(?<active>\d+)\/(?<active_total>\d+),
    \sReplicas:\s(?<replicas>\d+)\/(?<replicas_total>\d+)\n
    }x


    def cluster_running?
      query = shell_out!("scli --query_cluster --approve_certificate", {:returns => [0, 1, 7]})
      query.run_command
      query.exitstatus == 0 ? true : false
    end

    def get_inferred_upgrade
      query = shell_out!("scli --query_cluster --approve_certificate", {:returns => [0, 7]})
      query.run_command
      return false if query.exitstatus == 7
      state = cluster_state(query.stdout)
      inferred_mode = get_inferred_mode(state)
      if state[:cluster]['mode'] == inferred_mode[:mode]
        return false
      else
        return inferred_mode
      end
    end

    def empty_upgrade
      { mode: nil,
        nodes: {
          primary:  [{name: nil}],
          standbys: [{name: nil}],
          tbs:      [{name: nil}]
        }
      }
    end

    def primary_accessible?(host)
      port_is_open?(host, 9011) && port_is_open?(host, 6611)
    end

    def sds_accessible?(host)
      port_is_open?(host, 7072)
    end

    private

    def cluster_state(status_str)
      { cluster: CLUSTER_STATUS_REGEX.match(status_str),
        members: status_str.scan(NODE_STATUS_REGEX).map do |name, id, role, ips, mgmt_ip, port, version|
          { name:    name,
            id:      id,
            role:    role || "primary",
            ips:      ips,
            mgmt_ip: mgmt_ip,
            port:    port,
            version: version
          }
        end
      }
    end

    def get_inferred_mode(state)
      member_counts = member_counts(state)
      if member_counts['primary'] == 1 && member_counts['Manager'] == 2 && member_counts['Tie Breaker'] == 2
        return {
          mode: '5_node',
          nodes: {
            primary:  state[:members].find{|m| m[:role] == "primary"},
            standbys: state[:members].find_all{|m| m[:role] == "Manager"},
            tbs:      state[:members].find_all{|m| m[:role] == "Tie Breaker"}
          }
        }
      elsif member_counts['primary'] == 1 && member_counts['Manager'] == 1 && member_counts['Tie Breaker'] == 1
        return {
          mode: '3_node',
          nodes: {
            primary:  state[:members].find{|m| m[:role] == "primary"},
            standbys: state[:members].find_all{|m| m[:role] == "Manager"},
            tbs:      state[:members].find_all{|m| m[:role] == "Tie Breaker"}
          }
        }
      elsif member_counts['primary'] == 1 && member_counts['Manager'] == 0 && member_counts['Tie Breaker'] == 0
        return {
          mode: '1_node',
          nodes: {
            primary: state[:members].find{|m| m[:role] == "primary"},
            standbys: [{name: nil}],
            tbs: [{name: nil}]
          }
        }
      else
        return { mode: nil }
      end
    end

    def member_counts(state)
      counts = {'primary' => 0, 'Manager' => 0, 'Tie Breaker' => 0}
      state[:members].each {|m| counts[m[:role]] += 1}
      counts
    end

    def find_node(node, cluster)
      cluster.find{|n| n['hostname'] == node['hostname']}
    end

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

Chef::Recipe.include(ScaleIO::MDMHelper)
