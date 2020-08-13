# frozen_string_literal: true

require 'spec_helper'

describe 'dockerinstall::registry::base' do
  let(:pre_condition) do
    <<-PRECOND
    class { 'dockerinstall': }
    class { 'dockerinstall::compose': }
    PRECOND
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
