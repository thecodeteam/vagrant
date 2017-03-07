# Sysctl
module Sysctl
  class << self
    def config_file(node)
      return nil unless node['sysctl']['conf_dir'] || node['sysctl']['allow_sysctl_conf']

      node['sysctl']['conf_file']
    end

    def compile_attr(prefix, v)
      case v
      when Array
        "#{prefix}=#{v.join(' ')}"
      when String, Integer, Float, Symbol
        "#{prefix}=#{v}"
      when Hash, Chef::Node::Attribute
        prefix += '.' unless prefix.empty?
        v.map { |key, value| compile_attr("#{prefix}#{key}", value) }.flatten.sort
      else
        raise Chef::Exceptions::UnsupportedAction, "Sysctl cookbook can't handle values of type: #{v.class}"
      end
    end
  end
end
