require "rails_helper"

RSpec.describe HerokuCommands::Auth, type: :model do
  include Helpers::Api

  it "has a auth:logout command" do
    command = command_for("auth:logout")

    expect(command.task).to eql("auth")
    expect(command.subtask).to eql("logout")
    expect(command.application).to eql(nil)

    heroku_command = HerokuCommands::Auth.new(command)

    expect { heroku_command.run }.to_not raise_error

    expect do
      command.user.reload
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
