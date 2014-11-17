require 'facter'

Facter.add("scaleio_mdm_state") do
  setcode do

	output = Facter::Core::Execution.exec('ps auxw | grep mdm | egrep -v "bash|grep mdm"')

	"Running" if output
  end
end

Facter.add("scaleio_sds_state") do
  setcode do

	output = Facter::Core::Execution.exec('ps auxw | grep sds | egrep -v "bash|grep sds"')

	"Running" if output
  end
end