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

      # NEW Helpers
      def stub_pipelines(pipelines)
        pipelines = pipelines.is_a?(Array) ? pipelines : [pipelines]
        stub_json_request(:get,
                          "https://api.heroku.com/pipelines",
                          pipelines.to_json)
      end

      def stub_couplings(pipeline_id, apps, stage = "production")
        apps = apps.is_a?(Array) ? apps : [apps]
        couplings = apps.map do |app|
          { stage: stage, app: { id: app[:id] } }
        end
        url = "https://api.heroku.com/pipelines/#{pipeline_id}/pipeline-couplings"
        stub_json_request(:get,
                          url,
                          couplings.to_json)
      end

      def stub_2fa_check(app_id, args = {})
        locked = args[:locked]
        status = locked ? 403 : 200
        body = locked ? { id: "two_factor" } : {}
        stub_json_request(:get,
                          "https://api.heroku.com/apps/#{app_id}/config-vars",
                          body.to_json,
                          status)
      end

      def stub_heroku_app(id, name)
        app = { id: id, name: name }
        stub_json_request(:get, "https://api.heroku.com/apps/#{id}", app.to_json)
      end

      def stub_mapping_pipeline_repository(pipeline_id, repo_name_with_owner)
        url = "https://kolkrabbi.com/pipelines/#{pipeline_id}/repository"
        payload = { repository: { name: repo_name_with_owner } }
        stub_json_request(:get, url, payload.to_json)
      end

      def stub_pipeline_repository_not_found(pipeline_id)
        url = "https://kolkrabbi.com/pipelines/#{pipeline_id}/repository"
        stub_json_request(:get, url, {}.to_json, 404)
      end

      def stub_repository(name_with_owner, default_branch = "master")
        stub_json_request(:get,
                          "https://api.github.com/repos/#{name_with_owner}",
                          { default_branch: default_branch }.to_json)
      end

      def stub_required_contexts(name_with_owner, branch = "master")
        url = "https://api.github.com/repos/#{name_with_owner}/branches/#{branch}"
        stub_json_request(:get, url, {}.to_json)
      end

      def stub_deployment_conflict(repo)
        payload = { message: "Conflict: Commit status checks failed for master." }
        stub_json_request(:post,
                          "https://api.github.com/repos/#{repo}/deployments",
                          payload.to_json,
                          409)
      end

      def stub_deployment_status(repo)
        stub_json_request(:post,
                          "https://api.github.com/repos/#{repo}/deployments",
                          {}.to_json,
                          200)
      end

      def stub_pipeline_not_connected_to_github_flow(pipeline_id, pipeline_name)
        pipeline =  { id: pipeline_id, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: pipeline_name }

        stub_pipelines(pipeline)
        stub_couplings(pipeline[:id], app)

        stub_pipeline_repository_not_found(pipeline[:id])
      end

      def stub_missing_required_commit_status_flow(pipeline_name, app_name, repo)
        pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: app_name }

        stub_pipelines(pipeline)
        stub_couplings(pipeline[:id], app)
        stub_2fa_check(app[:id])
        stub_heroku_app(app[:id], app[:name])

        stub_mapping_pipeline_repository(pipeline[:id], repo)

        stub_repository(repo)
        stub_required_contexts(repo)

        stub_deployment_conflict(repo)
      end

      def stub_missing_environment_flow(pipeline_name, environments)
        pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: pipeline_name }

        stub_pipelines(pipeline)
        stub_couplings(pipeline[:id], app, environments[:available_env])
      end


      def stub_2fa_locked_app_flow(pipeline_name, app_name)
        pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: app_name }

        stub_pipelines(pipeline)

        stub_mapping_pipeline_repository(pipeline[:id], "heroku/#{app_name}")

        stub_couplings(pipeline[:id], app)
        stub_heroku_app(app[:id], app[:name])
        stub_2fa_check(app[:id], locked: true)
      end

      def stub_locked_deployment_flow(pipeline_name, app_name)
        pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: app_name }

        stub_pipelines(pipeline)

        stub_mapping_pipeline_repository(pipeline[:id], "heroku/#{app_name}")

        stub_couplings(pipeline[:id], app)
        stub_heroku_app(app[:id], app[:name])
        stub_2fa_check(app[:id])

        # Fake the lock
        Lock.new("escobar-app-#{app[:id]}").lock
      end

      def stub_multiple_apps_in_stage_flow(args = {})
        pipeline_name   = args[:pipeline_name]
        app_names       = args[:app_names]
        chosen_app_name = args[:chosen_app_name]
        repo            = args[:repo] || "atmos/hubot"

        pipeline = { id: SecureRandom.uuid, name: pipeline_name }

        stub_mapping_pipeline_repository(pipeline[:id], repo)

        apps = stubbed_apps_hash_from_names(app_names)

        stub_pipelines(pipeline)
        stub_couplings(pipeline[:id], apps)

        return unless chosen_app_name
        chosen_app = apps.detect { |app| app[:name] == chosen_app_name }
        stub_chosen_app(chosen_app, repo, pipeline)
      end

      def stubbed_apps_hash_from_names(app_names)
        app_names.map do |app_name|
          id = SecureRandom.uuid
          stub_heroku_app(id, app_name)
          { id: id, name: app_name }
        end
      end

      def stub_chosen_app(chosen_app, repo, pipeline)
        stub_2fa_check(chosen_app[:id])
        stub_mapping_pipeline_repository(pipeline[:id], repo)

        stub_repository(repo)
        stub_required_contexts(repo)
        stub_deployment_status(repo)
      end

      def stub_successful_deployment_flow(pipeline_name)
        pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
        app = { id: SecureRandom.uuid, name: pipeline_name }
        repo = "heroku/#{pipeline_name}"

        stub_pipelines(pipeline)
        stub_couplings(pipeline[:id], app)
        stub_heroku_app(app[:id], app[:name])
        stub_2fa_check(app[:id])
        stub_mapping_pipeline_repository(pipeline[:id], repo)

        stub_repository(repo)
        stub_required_contexts(repo)
        stub_deployment_status(repo)
      end

      # rubocop:enable Metrics/LineLength
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
