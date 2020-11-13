# frozen_string_literal: true

require 'spec_helper'

describe 'dockerinstall::registry::nginx' do
  let(:pre_condition) { 'include dockerinstall' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'server_name' => 'registry.domain.tld',
        }
      end

      it { is_expected.to compile }

      context 'with default settings' do
        it {
          is_expected.to contain_class('lsys::nginx')
        }

        it {
          is_expected.to contain_file('/etc/nginx/conf.d/mapping')
            .with_ensure('directory')
        }
      end
    end
  end
end
