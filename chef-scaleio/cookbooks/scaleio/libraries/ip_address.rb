require 'ipaddr'

module IPAddress
  module Helper

    def find_addresses_in_networks(node, networks)
      networks.map do |network|
        find_address_in_network(node, network)
      end.compact
    end

    def find_address_in_network(node, network)
      net = IPAddr.new(network)
      node['network']['interfaces'].each do |int_name, int|
        int['addresses'].each do |addr, addr_data|
          if addr_data["family"] == "inet" && net.include?(IPAddr.new(addr))
            return addr
          end
        end
      end
      nil
    end

  end
end

Chef::Recipe.include(IPAddress::Helper)
