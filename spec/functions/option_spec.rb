require 'spec_helper'

describe 'dockerinstall::option' do
  context 'with parameter bip' do
    it {
      is_expected.to run.with_params('bip', '172.30.0.1/16').and_return({'bip' => '172.30.0.1/16'})
    }
  end

  context 'with wrong parameter type' do
    it {
      is_expected.to run.with_params('bip', 1024).and_return({})
    }
    it {
      is_expected.to run.with_params('bip', '172.30.0.1').and_return({})
    }
  end
end
