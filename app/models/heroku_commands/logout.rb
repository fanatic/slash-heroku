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

    def run
      user.destroy
      @response = {
        attachments: [
          { text: "Successfully removed your user. :wink:" }
        ]
      }
    end
  end
end
