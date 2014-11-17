require 'facter'
require 'ipaddr'


scaleio_sds_network = Facter.value(:scaleio_sds_network)
if scaleio_sds_network 
  net = IPAddr.new("#{scaleio_sds_network}")
  ip_address_array = Facter.value(:ip_address_array)

  ip_address_array.each do |ip_address|
    if net.include?(ip_address) == true
      Facter.add("scaleio_sds_ip") do  
	    setcode do
	      ip_address
	    end
	  end
	end
  end	    
end