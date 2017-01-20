require "rails_helper"

RSpec.describe HerokuCommands::Auth, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
  end

  def heroku_handler_for(text)
    command = command_for(text)
    command.handler
  end

  it "has a auth:logout command" do
    command = heroku_handler_for("auth:logout")

    expect(command.task).to eql("auth")
    expect(command.subtask).to eql("logout")
    expect(command.application).to eql(nil)
    expect { command.run }.to_not raise_error

    expect do
      command.user.reload
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
