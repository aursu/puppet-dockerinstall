# frozen_string_literal: true

require 'spec_helper'

describe 'dockerinstall::profile::registry' do
  let(:facts) do
    {
      'stype' => 'web',
    }
  end

  let(:pre_condition) do
    <<-PRECOND
    class { 'dockerinstall': }
    class { 'dockerinstall::compose': }
    tlsinfo::certificate { 'f1453246': }
    PRECOND
  end

  on_supported_os.each do |os, os_facts|
    os_facts[:os]['selinux'] = { 'enabled' => false }
    os_facts[:os]['distro'] ||= {}
    os_facts[:os]['distro']['codename'] = case os
                                          when %r{ubuntu-16.04}
                                            'xenial'
                                          when %r{ubuntu-18.04}
                                            'bionic'
                                          when %r{ubuntu-20.04}
                                            'focal'
                                          end

    context "on #{os}" do
      let(:facts) do
        os_facts.merge('stype' => 'web')
      end

      let(:params) do
        {
          'server_name' => 'registry.domain.tld',
        }
      end

      it { is_expected.to compile }
    end
  end
end
