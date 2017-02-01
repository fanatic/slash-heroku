# Generates command body and posts it to slack
class ExecuteCommand
  attr_reader :command, :task

  REQUIRES_AUTHENTICATION = %w{pipeline pipelines deploy}.freeze

  def self.for(command)
    new(command).post_to_slack
  end

  def initialize(command)
    @command = command
    @task = command.task
  end

  def response
    handler.run
    handler.response
  end

  def post_to_slack
    SlackPostback.for(response, command.response_url)
  end

  def handler
    @handler ||=
      if logging_in || needs_authentication
        HerokuCommands::Login.new(command)
      else
        case task
        when "deploy"
          HerokuCommands::Deploy.new(command)
        when "logout"
          HerokuCommands::Logout.new(command)
        when "pipeline", "pipelines"
          HerokuCommands::Pipelines.new(command)
        when "releases"
          HerokuCommands::Releases.new(command)
        else # when "help"
          HerokuCommands::Help.new(command)
        end
      end
  end

  def needs_authentication
    REQUIRES_AUTHENTICATION.include?(task) && not_setup?
  end

  def logging_in
    command.task == "login"
  end

  def not_setup?
    !command.user.heroku_configured? || !command.user.github_configured?
  end

  def response_for(text)
    {
      attachments: [
        { text: text, response_type: "in_channel" }
      ]
    }
  end
end
