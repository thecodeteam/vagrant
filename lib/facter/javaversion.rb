require 'facter'

Facter.add("javaversion") do
  confine :osfamily => :redhat
  setcode do
    javaversion = `yum list installed |grep java`.split("\n")
    if javaversion
      version = []
      javaversion.each do |line|
        if line =~/^java/
          version << line.match(/\d{1}\.\d{1}/m)[0]
        end
      end
      version.max
    end
  end
end

