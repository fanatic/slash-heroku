# Module for handling User's tokens. Encrypting/Decrypting etc
module TokenManagement
  extend ActiveSupport::Concern

  included do
  end

  # Things exposed to the included class as class methods
  module ClassMethods
    def fernet_secret
      ENV["FERNET_SECRET"] ||
        raise("No FERNET_SECRET environmental variable set")
    end
  end

  def decrypt_value(value)
    Fernet.verifier(self.class.fernet_secret, value).message
  rescue Fernet::Token::InvalidToken, NoMethodError
    nil
  end

  def encrypt_value(value)
    Fernet.generate(self.class.fernet_secret, value)
  end

  def reset_creds
    reset_heroku
    self.enc_github_token = nil
    self.save
  end
end
