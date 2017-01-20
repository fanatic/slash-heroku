# Generates command body and posts it to slack
class ExecuteCommand
  attr_reader :command

  def self.for(command)
    new(command).run
  end

  def initialize(command)
    @command = command
  end

  def run
    handler.run
    postback_message(handler.response)
  end

  def handler
    @handler ||= case command.task
                 when "auth"
                   HerokuCommands::Auth.new(command)
                 when "deploy"
                   HerokuCommands::Deploy.new(command)
                 when "login"
                   HerokuCommands::Login.new(command)
                 when "pipeline", "pipelines"
                   HerokuCommands::Pipelines.new(command)
                 when "releases"
                   HerokuCommands::Releases.new(command)
                 else # when "help"
                   HerokuCommands::Help.new(command)
                 end
  end

  def postback_message(message)
    response = client.post do |request|
      request.url callback_uri.path
      request.body = message.to_json
      request.headers["Content-Type"] = "application/json"
    end

    Rails.logger.info action: "command#postback_message", body: response.body
  rescue StandardError => e
    Rails.logger.info "Unable to post back to slack: '#{e.inspect}'"
  end

  def callback_uri
    @callback_uri ||= Addressable::URI.parse(command.response_url)
  end

  def client
    @client ||= Faraday.new(url: "https://hooks.slack.com")
  end
end
