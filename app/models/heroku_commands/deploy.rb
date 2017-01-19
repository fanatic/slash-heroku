module HerokuCommands
  # Class for handling Deployment requests
  class Deploy < HerokuCommand
    attr_reader :info, :lock_value

    delegate :application, :branch, :forced, :hosts, :second_factor, to: :@info

    def initialize(command)
      super(command)

      @info = Deployment.from_text(command.command_text)
    end

    def self.help_documentation
      [
        "deploy <pipeline>/<branch> to <stage>/<app-name> - " \
        "deploy a branch to a pipeline"
      ]
    end

    def run
      @response = run_on_subtask
    end

    def environment
      @environment ||= info.environment || pipeline.default_environment
    end

    def deploy_application
      if application && !pipeline
        response_for("Unable to find a pipeline called #{application}")
      else
        return lock_was_not_acquired_message unless acquire_lock
        DeploymentRequest.process(self)
      end
    ensure
      release_lock
    end

    def deployment_complete_message(_payload, _sha)
      {}
    end

    def run_on_subtask
      case subtask
      when "default"
        if pipeline
          deploy_application
        else
          response_for("You're not authenticated with GitHub yet. " \
                       "<#{command.github_auth_url}|Fix that>.")
        end
      else
        response_for("deploy:#{subtask} is currently unimplemented.")
      end
    rescue StandardError => e
      raise e if Rails.env.test?
      Raven.capture_exception(e)
      response_for("Unable to fetch deployment info for #{application}.")
    end

    def repository_markup(deploy)
      name_with_owner = deploy.github_repository
      "<https://github.com/#{name_with_owner}|#{name_with_owner}>"
    end
    
    def lock_was_not_acquired_message
      msg = "Someone is already deploying to #{application}/#{environment}"
      response_for(msg)
    end

    def release_lock
      Lock.unlock_deployment(info, lock_value)
    end

    def acquire_lock
      @lock_value = Lock.lock_deployment(info)
    end

    def pipeline
      user.pipeline_for(application)
    end
  end
end
