require 'facter'

Facter.add("ip_address_array") do
  setcode do
   
	interfaces = Facter.value(:interfaces)
    interfaces_array = interfaces.split(',')
    ip_address_array = []

    interfaces_array.each do |interface|
      ipaddress = Facter.value("ipaddress_#{interface}")
      ip_address_array.push(ipaddress)
    end
    ssh_ip = Facter.value(:ssh_ip)
    ip_address_array.push(ssh_ip) unless !ssh_ip
    ip_address_array
    end
end

