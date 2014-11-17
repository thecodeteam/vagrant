require 'facter'

Facter.add("kernelshmmax") do
  confine :osfamily => :redhat
  setcode do
    shmmax = Facter::Util::Resolution.exec("sysctl kernel.shmmax")
    shmmax.scan(/\d/).join('')
  end
end

