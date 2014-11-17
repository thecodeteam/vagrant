# hosts_lookup.rb
# does a hosts lookup and returns an array of strings of the results
# modeled from https://github.com/dalen/puppet-dnsquery/blob/master/lib/puppet/parser/functions/dns_lookup.rb

module Puppet::Parser::Functions
  newfunction(:hosts_lookup, :type => :rvalue, :arity => 1, :doc => <<-EOS
    Does a hosts lookup and returns an array of addresses.
    EOS
  ) do |arguments|
    require 'resolv'

    res = Resolv::Hosts.new
    arg = arguments[0]

    ret = if arg.is_a? Array
      arg.collect { |e| res.getaddresses(e).to_s }.flatten
    else
      res.getaddresses(arg).collect { |r| r.to_s }
    end
    #raise Resolv::ResolvError, "Hosts result has no information for #{arg}" if ret.empty?
    ret = [] unless ret
    ret
  end
end