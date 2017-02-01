require "parse"

module HerokuCommands
  # Class for handling release info
  class Releases < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "releases -a PIPELINE - " \
          "Display the last 25 releases for apps in the pipeline."
      ]
    end

    def run
      @response = run_on_subtask
    end

    def github_client
      @github_client ||= Escobar::GitHub::Client.new(
        client.github_token, github_repository
      )
    end

    def releases_info
      if application
        app = Escobar::Heroku::App.new(client, application_for_releases)

        releases = app.releases_json
        deploys = github_client.deployments

        response = ::Parse::Releases.new(releases, deploys, github_repository)
        response_for_releases(response.markdown)
      else
        help_for_task
      end
    end

    def run_on_subtask
      releases_info
    rescue StandardError
      response_for("Unable to fetch recent releases for #{pipeline_name}.")
    end

    def dashboard_markup
      "<#{dashboard_link}|#{pipeline_name}>"
    end

    def dashboard_link
      "https://dashboard.heroku.com/pipelines/#{pipeline_name}"
    end

    def response_for_releases(releases)
      {
        mrkdwn: true,
        response_type: "in_channel",
        attachments: [
          {
            color: COLOR,
            text: releases,
            title: "#{dashboard_markup} - Recent #{environment} releases",
            fallback: "Latest releases for Heroku pipeline #{pipeline_name}"
          }
        ]
      }
    end

    delegate :default_environment, :github_repository, to: :pipeline

    def parsed_environment
      match = command.command_text.match(/in ([-_\.0-9a-z]+)/)
      env = match[1] if match
      case env
      when "prod", "prd"
        "production"
      when "stg"
        "staging"
      else
        default_environment
      end
    end

    def environment
      parsed_environment
    end

    def application_for_releases
      pipeline.environments[environment].first.app.id
    end

    def pipeline
      user.pipeline_for(pipeline_name)
    end

    def available_pipelines
      user.pipelines
    end

    def pipeline_name
      application
    end
  end
end
