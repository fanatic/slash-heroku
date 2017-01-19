require "rails_helper"

RSpec.describe HerokuCommands::Auth, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
  end

  def heroku_handler_for(text)
    command = command_for(text)
    command.handler
  end

  it "prints the user's email if properly onboarded" do
    command = heroku_handler_for("login")

    response_info = fixture_data("api.heroku.com/account/info")
    stub_request(:get, "https://api.heroku.com/account")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    expect(command.task).to eql("login")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql(nil)
    expect { command.run }.to_not raise_error

    expect(command.response[:attachments].size).to eql(1)
    attachment = command.response[:attachments].first
    expect(attachment[:text]).to match("atmos@atmos.org")
  end

  it "prompts the user to onboard if not authed" do
    command = heroku_handler_for("login")

    command.user.heroku_token = nil
    command.user.github_token = nil
    command.user.save

    expect(command.task).to eql("login")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql(nil)
    expect { command.run }.to_not raise_error

    expect(command.response[:attachments].size).to eql(1)
    attachment = command.response[:attachments].first
    expect(attachment[:text]).to match("not authenticated with GitHub yet")
  end
end
