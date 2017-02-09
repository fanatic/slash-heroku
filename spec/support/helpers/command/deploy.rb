module Helpers
  module Command
    module Deploy
      PIPELINE_IDS = [
        "531a6f90-bd76-4f5c-811f-acc8a9f4c111",
        "6c18c922-6eee-451c-b7c6-c76278652ccc"
      ].freeze
      APP_IDS = [
        "27bde4b5-b431-4117-9302-e533b887faaa",
        "b0deddbf-cf56-48e4-8c3a-3ea143be2333",
        "760bc95e-8780-4c76-a688-3a4af92a3eee",
        "860bc95e-8780-4c76-a688-3a4af92a3eee",
        "c0deddbf-cf56-48e4-8c3a-3ea143be2333"
      ].freeze
      REPOS = [
        "atmos/hubot",
        "heroku/beeper"
      ].freeze

      # rubocop:disable Metrics/LineLength
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def stub_deploy_command(heroku_token)
        stub_account_info(heroku_token)
        stub_pipeline_info(heroku_token)
        stub_app_info(heroku_token)
        stub_app_is_not_2fa(heroku_token)
        stub_build(heroku_token)
        stub_github_status
      end

      def stub_build(heroku_token)
        stub_request(:post, "https://api.heroku.com/apps/hubot/builds")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: { id: "191853f6-0635-44cc-8d97-ef8feae0e178" }.to_json, headers: {})

        stub_request(:post, "https://api.heroku.com/apps/beeper-production-foo/builds")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: { id: "191853f6-0635-44cc-8d97-ef8feae0e178" }.to_json, headers: {})

        PIPELINE_IDS.each do |p_id|
          response_info = fixture_data("kolkrabbi.com/pipelines/#{p_id}/repository")
          stub_request(:get, "https://kolkrabbi.com/pipelines/#{p_id}/repository")
            .to_return(status: 200, body: response_info)
        end

        sha = "27bd10a885d27ba4db2c82dd34a199b6a0a8149c"
        REPOS.each do |repo|
          response_info = fixture_data("api.github.com/repos/#{repo}/index")
          stub_request(:get, "https://api.github.com/repos/#{repo}")
            .to_return(status: 200, body: response_info, headers: {})

          response_info = fixture_data("api.github.com/repos/#{repo}/branches/production")
          stub_request(:get, "https://api.github.com/repos/#{repo}/branches/production")
            .to_return(status: 200, body: response_info, headers: {})

          response_info = fixture_data("api.github.com/repos/#{repo}/tarball/#{sha}")
          stub_request(:head, "https://api.github.com/repos/#{repo}/tarball/#{sha}")
            .to_return(status: 200, body: response_info, headers: { "Location" => "https://codeload.github.com/#{repo}/legacy.tar.gz/master" })

          url = "https://api.github.com/repos/#{repo}/deployments/4307227"
          stub_request(:post, "https://api.github.com/repos/#{repo}/deployments")
            .to_return(status: 200, body: { sha: sha, url: url }.to_json, headers: {})
        end
      end

      def stub_github_status
        REPOS.each do |repo|
          stub_request(:post, "https://api.github.com/repos/#{repo}/deployments/4307227/statuses")
            .to_return(status: 200, body: {}.to_json, headers: {})
        end
      end

      def stub_app_is_not_2fa(heroku_token)
        APP_IDS.each do |app_id|
          stub_request(:get, "https://api.heroku.com/apps/#{app_id}/config-vars")
            .with(headers: default_heroku_headers(heroku_token))
            .to_return(status: 200, body: {}.to_json, headers: {})
        end
      end

      def stub_app_info(heroku_token)
        APP_IDS.each do |app_id|
          response_info = fixture_data("api.heroku.com/apps/#{app_id}")
          stub_request(:get, "https://api.heroku.com/apps/#{app_id}")
            .with(headers: default_heroku_headers(heroku_token))
            .to_return(status: 200, body: response_info, headers: {})
        end
      end

      def stub_pipeline_info(heroku_token)
        response_info = fixture_data("api.heroku.com/pipelines/info")
        stub_request(:get, "https://api.heroku.com/pipelines")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: response_info, headers: {})

        PIPELINE_IDS.each do |p_id|
          fixture_path = "api.heroku.com/pipelines/#{p_id}/pipeline-couplings"
          url_to_stub = "https://api.heroku.com/pipelines/#{p_id}/pipeline-couplings"
          response_info = fixture_data(fixture_path)
          stub_request(:get, url_to_stub)
            .with(headers: default_heroku_headers(heroku_token))
            .to_return(status: 200, body: response_info, headers: {})
        end
      end

      def stub_account_info(heroku_token)
        response_info = fixture_data("api.heroku.com/account/info")
        stub_request(:get, "https://api.heroku.com/account")
          .with(headers: default_heroku_headers(heroku_token))
          .to_return(status: 200, body: response_info, headers: {})
      end

      # rubocop:enable Metrics/LineLength
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
