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

    def releases_info
      if application
        app = Escobar::Heroku::App.new(client, application)
        response = app.releases_json
        response_for_releases(response)
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
      "https://dashboard.heroku.com/apps/#{application}"
    end

    def response_for_releases(releases)
      {
        mrkdwn: true,
        response_type: "in_channel",
        attachments: [
          {
            color: COLOR,
            text: response_markdown_for(releases),
            title: "#{dashboard_markup(application)} - Recent releases",
            fallback: "Latest releases for Heroku application #{application}"
          }
        ]
      }
    end
  end
end
