require 'spec_helper'
describe 'scaleio' do

  context 'with defaults for all parameters' do
    it { should contain_class('scaleio') }
  end
end
