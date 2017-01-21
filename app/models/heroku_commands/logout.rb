module HerokuCommands
  # Class for handling logging a user out
  class Logout < HerokuCommand
    def initialize(command)
      super(command)
    end

    def self.help_documentation
      [
        "logout - Verify the user is authenticated with Heroku and GitHub."
      ]
    end

    def email
      user.heroku_user_information &&
        user.heroku_user_information["email"]
    end

    def run
      @response = if user.onboarded?
                    authenticated_user_response
                  else
                    user_onboarding_response
                  end
    end

    def authenticated_user_response
      {
        attachments: [
          { text: "You're authenticated as #{email} on Heroku." }
        ]
      }
    end

    def user_onboarding_response
      if user.heroku_configured?
        authenticate_github_response
      else
        authenticate_heroku_response
      end
    end
  end
end
