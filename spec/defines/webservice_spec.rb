require 'spec_helper'

describe 'dockerinstall::webservice' do
  let(:pre_condition) do
    <<-PRECOND
    include dockerinstall
    include dockerinstall::compose
    PRECOND
  end
  let(:title) { 'namevar' }
  let(:params) do
    {
      docker_image: 'jenkinsci/blueocean:1.19.0',
      manage_image: true,
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
          .with_configuration(%r{^version: "3.5"$})
      }

      it {
        is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
          .with_configuration(%r{^[ ]{2}namevar:$})
      }

      it {
        is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
          .with_configuration(%r{^[ ]{4}image: jenkinsci/blueocean:1\.19\.0$})
      }

      context 'when docker ulimits specified' do
        let(:params) do
          super().merge(
            docker_ulimits: {
              memlock: [-1, -1],
              nofile: 65535,
            },
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{6}memlock:$})
            .with_configuration(%r{^[ ]{6}  soft: -1$})
            .with_configuration(%r{^[ ]{6}  hard: -1$})
        }

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{6}nofile: 65535$})
        }
      end
    end
  end
end
