# A incoming deployment requests that's valid and available to release.
class DeploymentRequest
  attr_accessor :command_handler

  delegate :pipeline_name, :branch, :environment, :forced,
           :hosts, :second_factor,
           to: :command_handler

  delegate :command, to: :command_handler
  delegate :channel_name, :team_id, to: :command

  delegate :user, to: :command
  delegate :slack_user_id, :slack_user_name, to: :user

  def self.process(command_handler)
    request = new(command_handler)
    request.process
  end

  def initialize(command_handler)
    @command_handler = command_handler
  end

  def process
    return app_is_locked unless lock_acquired?
    return pipeline_has_multiple_apps if pipeline_has_multiple_apps?

    heroku_application.preauth(second_factor) if second_factor
    poll_heroku_build(create_heroku_build)
  rescue Escobar::Heroku::BuildRequest::Error => e
    unlock
    handle_escobar_exception(e)
  rescue StandardError => e
    unlock
    handle_exception(e)
  end

  private

  def lock_acquired?
    Lock.new(heroku_application.cache_key).lock
  end

  def unlock
    Lock.new(heroku_application.cache_key).unlock
  end

  def app_is_locked
    msg = "Someone is already deploying to #{heroku_application.name}"
    command_handler.error_response_for(msg)
  end

  def pipeline_has_multiple_apps
    apps = app_names.join(", ")
    msg = "There are more than one app in #{environment} for #{pipeline.name}: "
    msg += "#{apps}. This is not supported yet."
    command_handler.error_response_for(msg)
  end

  def create_heroku_build
    heroku_build = heroku_build_request.create(
      "deploy", environment, branch, forced, notify_payload
    )
    heroku_build.command_id = command.id
    heroku_build
  end

  def command_expired?
    command.created_at < 60.seconds.ago
  end

  def notify_payload
    {
      notify: {
        room: channel_name,
        team_id: team_id,
        user: slack_user_id,
        user_name: slack_user_name
      }
    }
  end

  def default_heroku_application
    @default_heroku_application ||=
      pipeline.default_heroku_application(environment)
  end

  def pipeline
    @pipeline ||= command_handler.pipeline
  end

  def apps
    @apps ||= pipeline.environments[environment]
  end

  def pipeline_has_multiple_apps?
    apps.count > 1
  end

  def app_names
    apps.map(&:name)
  end

  def heroku_application
    @heroku_application ||= default_heroku_application
  end

  def heroku_build_request
    @heroku_build_request ||= heroku_application.build_request_for(pipeline)
  end

  def handle_escobar_exception(error)
    unless command_expired?
      CommandExecutorJob
        .set(wait: 0.5.seconds)
        .perform_later(command_id: command.id)
    end

    if command.processed_at.nil?
      command_handler.error_response_for_escobar(error)
    else
      {}
    end
  end

  def handle_exception(e)
    Raven.capture_exception(e)
    command_handler.error_response_for(e.message)
  end

  def poller_arguments(heroku_build)
    heroku_build.to_job_json.merge(user_id: user.id)
  end

  def poll_heroku_build(heroku_build)
    DeploymentPollerJob
      .set(wait: 10.seconds)
      .perform_later(poller_arguments(heroku_build))
    {}
  end
end
