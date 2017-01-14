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
        Rails.logger.info body
        app.client.heroku.post("/apps/#{app.name}/builds", body)
      end
    end
  end
end
