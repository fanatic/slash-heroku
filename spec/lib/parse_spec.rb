require "rails_helper"
require_relative "../../lib/parse.rb"

RSpec.describe Parse::Releases do
  describe ".all" do
    it "returns a list of releases with heroku and github information" do
      releases =
        decoded_fixture_data("api.heroku.com/releases/slash-h-production/list")
      deploys =
        decoded_fixture_data(
          "api.github.com/repos/atmos/slash-heroku/deployments"
        )

      releases_list = Parse::Releases.new(releases, deploys).all
      expect(releases_list.count).to eq(10)

      release_with_sha_and_ref = releases_list.first
      expect(release_with_sha_and_ref.sha).to eq("e046008")
      expect(release_with_sha_and_ref.ref).to eq("more-debug-info")

      config_change = releases_list[3]
      expect(config_change.sha).to eq(nil)
      expect(config_change.ref).to eq(nil)

      release_with_no_ref = releases_list.last
      expect(release_with_no_ref.sha).to eq("a2fa2f9")
      expect(release_with_no_ref.ref).to eq("a2fa2f9")
    end
  end
end
