describe Cluster::ConfigChecks::RealUsers do
  include EnvironmentHelpers

  it 'does not raise when there is at least one real user' do
    stub_config_to_include(
      stack: {
        users: [
          user_name: 'alincoln'
        ]
      }
    )

    expect { described_class.sane? }.not_to raise_error
  end

  it 'raises when there are no users' do
    stub_config_to_include( stack: { users: [ ] } )

    expect { described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::NoSshUsers
    )
  end

  it 'raises when the fake user has not been removed' do
    stub_config_to_include(
      stack: {
        users: [
          { user_name: 'alincoln' },
          { user_name: 'FILL_ME_IN' }
        ]
      }
    )

    expect { described_class.sane? }.to raise_error(
      Cluster::ConfigChecks::TemplateUserNotRemoved
    )
  end

  it_behaves_like 'a registered configuration check'
end
