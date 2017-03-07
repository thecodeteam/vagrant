if defined?(ChefSpec)
  chefspec_version = Gem.loaded_specs['chefspec'].version
  if chefspec_version < Gem::Version.new('4.1.0')
    ChefSpec::Runner.define_runner_method :sysctl_param
  else
    ChefSpec.define_matcher :sysctl_param
  end

  def apply_sysctl_param(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:sysctl_param, :apply, resource_name)
  end

  def remove_sysctl_param(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:sysctl_param, :remove, resource_name)
  end
end
