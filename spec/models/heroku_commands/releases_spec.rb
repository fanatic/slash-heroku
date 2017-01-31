require "rails_helper"

RSpec.describe HerokuCommands::Releases, type: :model do
  before do
    Timecop.freeze(Time.zone.local(2016, 3, 13))
  end

  after do
    Timecop.return
  end

  # rubocop:disable Metrics/LineLength
  it "has a releases -a command" do
    command = command_for("releases -a atmos-dot-org")

    response_info = fixture_data("api.heroku.com/releases/atmos-dot-org/list")
    stub_request(:get, "https://api.heroku.com/apps/atmos-dot-org/releases")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    expect(command.task).to eql("releases")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql("atmos-dot-org")

    heroku_command = HerokuCommands::Releases.new(command)

    expect { heroku_command.run }.to_not raise_error

    expect(heroku_command.response[:response_type]).to eql("in_channel")
    expect(heroku_command.response[:attachments].size).to eql(1)
    attachment = heroku_command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Latest releases for Heroku application atmos-dot-org")
    expect(attachment[:pretext]).to eql(nil)
    expect(attachment[:text].split("\n").size).to eql(9)
    expect(attachment[:title])
      .to eql("<https://dashboard.heroku.com/apps/atmos-dot-org|atmos-dot-org> - Recent releases")
    expect(attachment[:title_link]).to eql(nil)
    expect(attachment[:fields]).to eql(nil)
  end
  # rubocop:enable Metrics/LineLength
end
