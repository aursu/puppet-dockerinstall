require 'spec_helper'

describe 'Dockerinstall::Log::JSONFile' do
  it { is_expected.to allow_values({ }) }
  it { is_expected.to allow_values({ 'max-size' => '0' }) }
  it { is_expected.to allow_values({ 'max-size' => '-1' }) }
  it { is_expected.to allow_values({ 'max-size' => '100' }) }
  it { is_expected.to allow_values({ 'max-size' => '100m' }) }
  it { is_expected.to allow_values({ 'compress' => 'true' }) }
  it { is_expected.not_to allow_values({ 'compress' => true }) }
  it { is_expected.not_to allow_values({ 'max-size' => '100M' }) }
  it { is_expected.not_to allow_values({ 'max-size' => '-2' }) }
  it { is_expected.not_to allow_values({ 'max-size' => 2 }) }
end