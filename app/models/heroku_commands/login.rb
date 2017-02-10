module HerokuCommands
  # Class for handling authenticating a user
  class Login < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "login - Verify the user is authenticated with Heroku and GitHub."
      ]
    end

    def email
      user.heroku_user_information &&
        user.heroku_user_information["email"]
    end

    def run
      user_response
    end

    private

    def user_response
      {
        text: response_main_text,
        attachments: [
          {
            color: response_color,
            mrkdwn_in: %w{text pretext fields},
            attachment_type: "default",
            fields: [heroku_response, github_response]
          }
        ]
      }
    end

    def response_main_text
      if user.onboarded?
        "Your account is fully setup"
      elsif user.onboarding?
        "You are half the way done"
      else
        "Let's setup this account"
      end
    end

    def response_color
      if user.onboarded?
        "#46ea1f"
      elsif user.onboarding?
        "#ffa807"
      else
        "#f00a1f"
      end
    end

    def heroku_response
      text = if user.heroku_configured?
               "You're authenticated as #{user.heroku_email} on Heroku."
             else
               "Please <#{command.slack_auth_url}|sign in to Heroku>."
             end

      {
        title: "Heroku",
        value: text,
        short: true
      }
    end

    def github_response
      text = if user.github_configured?
               "You're authenticated as #{user.github_login} on GitHub."
             else
               "Please <#{command.github_auth_url}|sign in to GitHub>."
             end

      {
        title: "GitHub",
        value: text,
        short: true
      }
    end
  end
end
