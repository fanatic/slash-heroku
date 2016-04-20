# Module for handling User's GitHub tokens.
module GitHubTokenManagement
  extend ActiveSupport::Concern

  included do
  end

  # Things exposed to the included class as class methods
  module ClassMethods
  end

  def github_token
    decrypt_value(self[:enc_github_token])
  end

  def github_token=(token)
    self[:enc_github_token] = encrypt_value(token)
  end
end
