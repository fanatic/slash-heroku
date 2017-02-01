require "parse"

module HerokuCommands
  # Class for handling release info
  class Releases < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "releases -a APP - Display the last 10 releases for APP."
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
      response_for("Unable to fetch recent releases for #{application}.")
    end

    def response_markdown_for(releases)
      releases.map do |release|
        "v#{release['version']} - #{release['description']} - " \
        "#{release['user']['email']} - " \
          "#{time_ago_in_words(release['created_at'])}"
      end.join("\n")
    end

    def dashboard_markup(application)
      "<#{dashboard_link(application)}|#{application}>"
    end

    def dashboard_link(application)
      "https://dashboard.heroku.com/pipelines/#{application}"
    end

    def response_for_releases(releases)
      {
        mrkdwn: true,
        response_type: "in_channel",
        attachments: [
          {
            color: COLOR,
            text: releases,
            title: "#{dashboard_markup(application)} - Recent releases",
            fallback: "Latest releases for Heroku pipeline #{application}"
          }
        ]
      }
    end

    delegate :default_environment, :github_repository, to: :pipeline

    def application_for_releases
      pipeline.environments[default_environment].first.app.id
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
