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
          .without_configuration(%r{^version:})
      }

      it {
        is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
          .with_configuration(%r{^[ ]{2}namevar:$})
      }

      it {
        is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
          .with_configuration(%r{^[ ]{4}image: jenkinsci/blueocean:1\.19\.0$})
      }

      it {
        is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
          .with_configuration(%r{^[ ]{4}restart: always$})
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

      context 'when docker build specified' do
        let(:params) do
          super().merge(
            docker_build: true,
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}build:$})
            .with_configuration(%r{^[ ]{4}  context: \.$})
            .with_configuration(%r{^[ ]{4}  dockerfile: Dockerfile$})
        }

        context 'when docker file and context specified' do
          let(:params) do
            super().merge(
              docker_context: '/var/run/compose/centos',
              docker_file: '6/curl/Dockerfile',
            )
          end

          it {
            is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
              .with_configuration(%r{^[ ]{4}build:$})
              .with_configuration(%r{^[ ]{4}  context: /var/run/compose/centos$})
              .with_configuration(%r{^[ ]{4}  dockerfile: 6/curl/Dockerfile$})
          }
        end

        context 'when docker build args specified' do
          let(:params) do
            super().merge(
              docker_build_args: { 'centos' => '7.8.2003' },
            )
          end

          it {
            is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
              .with_configuration(%r{^[ ]{4}build:$})
              .with_configuration(%r{^[ ]{4}  args:$})
              .with_configuration(%r{^[ ]{4}    centos: 7.8.2003$})
          }
        end
      end

      context 'when docker command specified' do
        let(:params) do
          super().merge(
            docker_command: 'bundle exec thin -p 3000',
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}command: bundle exec thin -p 3000$})
        }
      end

      context 'when docker command specified as array' do
        let(:params) do
          super().merge(
            docker_command: ['bundle', 'exec', 'thin', '-p', '3000'],
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}command: \["bundle", "exec", "thin", "-p", "3000"\]$})
        }
      end

      context 'when privileged flag is set' do
        let(:params) do
          super().merge(
            privileged: true,
          )
        end

        it {
          is_expected.to contain_dockerinstall__composeservice('namevar/namevar')
            .with_configuration(%r{^[ ]{4}privileged: true$})
        }
      end
    end
  end
end
