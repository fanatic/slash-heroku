Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV["GITHUB_OAUTH_ID"], ENV["GITHUB_OAUTH_SECRET"], scope: "repo_deployemtn,repo:status"
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :heroku, ENV["HEROKU_OAUTH_ID"], ENV["HEROKU_OAUTH_SECRET"], scope: "write-restricted", fetch_info: true
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :slack, ENV["SLACK_OAUTH_ID"], ENV["SLACK_OAUTH_SECRET"], scope: "identify,commands"
end
