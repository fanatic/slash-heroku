require "rails_helper"

RSpec.describe ExecuteCommand, type: :model do
  include Helpers::Command::Pipelines

  describe "Pipelines command" do
    let(:command) { command_for("pipelines") }

    it "checks to make sure you're authenticated with heroku" do
      command.user.heroku_token = nil
      command.user.save

      stub_please_sign_into_heroku

      ExecuteCommand.for(command)

      expect(stub_please_sign_into_heroku).to have_been_requested
    end

    it "checks to make sure you're authenticated with Github" do
      command.user.github_token = nil
      command.user.save

      stub_please_sign_into_github

      ExecuteCommand.for(command)

      expect(stub_please_sign_into_github).to have_been_requested
    end

    it "lists available pipelines" do
      command.user.github_token = SecureRandom.hex(24)
      command.user.heroku_token = SecureRandom.hex(24)
      command.user.save

      stub_pipelines_command(command.user.heroku_token)

      message = "You can deploy: hubot, slash-heroku."
      slack_body = slack_body(message)
      stub = stub_slack_request(slack_body)

      ExecuteCommand.for(command)

      expect(stub).to have_been_requested
    end
  end

  describe "Deploy command" do
    let(:command) { command_for("deploy hubot") }
    it "checks to make sure you're authenticated with heroku" do
      command.user.heroku_token = nil
      command.user.save

      stub_please_sign_into_heroku

      ExecuteCommand.for(command)

      expect(stub_please_sign_into_heroku).to have_been_requested
    end

    it "checks to make sure you're authenticated with Github" do
      command.user.github_token = nil
      command.user.save

      stub_please_sign_into_github

      ExecuteCommand.for(command)

      expect(stub_please_sign_into_github).to have_been_requested
    end
  end

  def slack_body(message)
    {
      attachments:
        [
          {
            text: message
          }
        ]
    }.to_json
  end

  def stub_please_sign_into_heroku
    message = "Please <#{command.slack_auth_url}|sign in to Heroku>."
    slack_body = slack_body(message)
    stub_slack_request(slack_body)
  end

  def stub_please_sign_into_github
    message = "You're not authenticated with GitHub yet. " \
                "<#{command.github_auth_url}|Fix that>."
    slack_body = slack_body(message)
    stub_slack_request(slack_body)
  end
end
