# Wrapper around Escobar pipeline info
class Pipeline
  attr_reader :application, :client_token, :github_token
  def initialize(application, github_token, client_token)
    @application = application
    @github_token = github_token
    @client_token = client_token
  end
  def pipeline
    pipelines[application]
  end

  def pipelines
    @pipelines ||= pipelines!
  end

  def pipelines!
    return unless github_token
    Escobar::Client.new(github_token, client_token)
  end
end
