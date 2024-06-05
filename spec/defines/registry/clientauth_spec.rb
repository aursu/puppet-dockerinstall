require 'spec_helper'

describe 'dockerinstall::registry::clientauth' do
  let(:pre_condition) do
    <<-PRECOND
    class { 'dockerinstall': }
    PRECOND
  end
  let(:title) { 'namevar' }
  let(:params) do
    {}
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
