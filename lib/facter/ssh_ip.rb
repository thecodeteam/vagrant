require 'facter'

Facter.add("ssh_ip") do
  begin
    ssh_ip = File.open('/etc/ssh_ip', &:readline).chop
    setcode do
      ssh_ip
    end
  rescue
  end
end

