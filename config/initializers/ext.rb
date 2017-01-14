module Escobar
  module Heroku
    # Class representing a heroku build request
    class BuildRequest
      def create_heroku_build
        body = {
          source_blob: {
            url: github_client.archive_link(sha),
            version: sha,
            version_description: "#{pipeline.github_repository}:#{sha}"
          }
        }
        Rails.logger.info action: :create_heroku_build, body: body
        app.client.heroku.post("/apps/#{app.name}/builds", body)
      end

      def post(path, body)
        response = client.post do |request|
          request.url path
          request.headers["Accept"] = heroku_accept_header(3)
          request.headers["Accept-Encoding"] = ""
          request.headers["Content-Type"]    = "application/json"
          if token
            request.headers["Authorization"] = "Bearer #{token}"
          end
          request.body = body.to_json
        end

        Rails.logger.info action: :heroku_post, body: response

        JSON.parse(response.body)
      rescue StandardError
        response && response.body
      end
    end
  end
  module GitHub
    class Client
      def create_deployment(options)
        body = {
          ref: options[:ref] || "master",
          task: "deploy",
          auto_merge: false,
          required_contexts: options[:required_contexts] || [],
          payload: options[:payload] || {},
          environment: options[:environment] || "staging",
          description: "Shipped from chat with slash-heroku"
        }
        Rails.logger.info action: :create_github_deployment, body: body

        post("/repos/#{name_with_owner}/deployments", body)
      end

      def create_deployment_status(url, payload)
        uri = URI.parse(url)
        Rails.logger.info action: :create_github_deployment_status, body: payload
        post("#{uri.path}/statuses", payload)
      end

      def post(path, body)
        response = client.post do |request|
          request.url path
          request.headers["Accept"] = accept_headers
          request.headers["Content-Type"] = "application/json"
          request.headers["Authorization"] = "token #{token}"
          request.body = body.to_json
        end

        Rails.logger.info action: :github_post_success, response: response
        JSON.parse(response.body)
      rescue StandardError
        Rails.logger.info action: :github_post, response: response
        response && response.body
      end
    end
  end
end
