require 'spec_helper'

describe 'dockerinstall::install' do
  let(:pre_condition) { 'include dockerinstall' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      case os
      when %r{ubuntu}
        it {
          is_expected.to contain_package('docker')
            .that_requires('Apt::Source[docker]')
        }
      when %r{centos}
        it {
          is_expected.to contain_package('docker')
            .that_requires('Yumrepo[docker-ce]')
        }
      end
    end
  end
end
