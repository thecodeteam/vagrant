require 'facter'

if File.exist?("/bin/emc/scaleio/drv_cfg.txt") 
	drv_cfg_mdm_primary_ip = Facter::Core::Execution.exec("/bin/cat /bin/emc/scaleio/drv_cfg.txt | grep \"^mdm\" | awk '{print $2}' 2> /dev/null")
	if drv_cfg_mdm_primary_ip 
		Facter.add("scaleio_primary_ip") do
		  setcode do
		  	Facter::Core::Execution.exec("/bin/scli --mdm_ip #{drv_cfg_mdm_primary_ip} --query_cluster 2> /dev/null | grep 'Primary IP' | awk '{print $3}'")
		  end
		end

		Facter.add("scaleio_secondary_ip") do
		  setcode do
		  	Facter::Core::Execution.exec("/bin/scli --mdm_ip #{drv_cfg_mdm_primary_ip} --query_cluster 2> /dev/null | grep 'Secondary IP' | awk '{print $3}'")
		  end
		end

		Facter.add("scaleio_management_ip") do
		  setcode do
		  	Facter::Core::Execution.exec("/bin/scli --mdm_ip #{drv_cfg_mdm_primary_ip} --query_cluster 2> /dev/null | grep 'Management IP' | awk '{print $3}'")
		  end
		end

		Facter.add("scaleio_tb_ip") do
		  setcode do
		  	Facter::Core::Execution.exec("/bin/scli --mdm_ip #{drv_cfg_mdm_primary_ip} --query_cluster 2> /dev/null | grep 'Tie-Breaker IP' | awk '{print $3}'")
		  end
		end
	end
end