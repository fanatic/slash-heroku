require "rails_helper"

RSpec.describe ReleasePoller, type: :model do
  let(:user) do
    u = create_atmos
    u.heroku_token = SecureRandom.hex(24)
    u.heroku_refresh_token = SecureRandom.hex(16)
    u.heroku_expires_at = 15.minutes.from_now
    u.github_token = SecureRandom.hex(24)
    u.save
    u
  end

  let(:deployment_url) do
    "https://api.github.com/repos/atmos/slash-heroku/deployments/123456"
  end

  let(:release_args) do
    {
      app_name: "slash-h-production",
      build_id: "b80207dc-139f-4546-aedc-985d9cfcafab",
      release_id: "23fe935d-88c8-4fd0-b035-10d44f3d9059",
      deployment_url: deployment_url,
      user_id: user.id,
      name: "slash-heroku"
    }
  end

  # rubocop:disable Metrics/LineLength
  it "successfully polls a release" do
    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/builds/#{release_args[:build_id]}")
    stub_request(:get, "https://api.heroku.com/apps/slash-h-production/builds/#{release_args[:build_id]}")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
      .to_return(status: 200, body: response_info)

    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/releases/#{release_args[:release_id]}")
    stub_request(:get, "https://api.heroku.com/apps/slash-h-production/releases/#{release_args[:release_id]}")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    stub_request(:post, "#{deployment_url}/statuses")
      .to_return(status: 200, body: {}.to_json, headers: {})

    poller = ReleasePoller.run(release_args)
    expect(poller.release.status).to eql("succeeded")
  end
  # rubocop:enable Metrics/LineLength

  # rubocop:disable Metrics/LineLength
  it "retry later if release is pending" do
    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/builds/#{release_args[:build_id]}")
    stub_request(:get, "https://api.heroku.com/apps/slash-h-production/builds/#{release_args[:build_id]}")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
      .to_return(status: 200, body: response_info)

    response_info = fixture_data("api.heroku.com/releases/pending")
    stub_request(:get, "https://api.heroku.com/apps/slash-h-production/releases/#{release_args[:release_id]}")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    status_update = stub_request(:post, "#{deployment_url}/statuses")
                    .to_return(status: 200, body: {}.to_json, headers: {})

    poller = nil
    ActiveJob::Base.queue_adapter = :test
    expect do
      poller = ReleasePoller.run(release_args)
    end.to have_enqueued_job(ReleasePollerJob)
    expect(status_update).to_not have_been_requested
    expect(poller.release.status).to eql("pending")
  end
  # rubocop:enable Metrics/LineLength

  # rubocop:disable Metrics/LineLength
  it "unlocks the app if the release succeeds" do
    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/builds/#{release_args[:build_id]}")
    stub_request(:get, "https://api.heroku.com/apps/slash-h-production/builds/#{release_args[:build_id]}")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
      .to_return(status: 200, body: response_info)

    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/releases/#{release_args[:release_id]}")
    stub_request(:get, "https://api.heroku.com/apps/slash-h-production/releases/#{release_args[:release_id]}")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    stub_request(:post, "#{deployment_url}/statuses")
      .to_return(status: 200, body: {}.to_json, headers: {})

    poller = ReleasePoller.new(release_args)
    lock = Lock.new(poller.release.app.cache_key)
    lock.lock
    poller.run
    expect(lock).to_not be_locked
  end
  # rubocop:enable Metrics/LineLength

  # rubocop:disable Metrics/LineLength
  it "retry later if release is pending" do
    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/builds/#{release_args[:build_id]}")
    stub_request(:get, "https://api.heroku.com/apps/slash-h-production/builds/#{release_args[:build_id]}")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")
      .to_return(status: 200, body: response_info)

    response_info = fixture_data("api.heroku.com/releases/pending")
    stub_request(:get, "https://api.heroku.com/apps/slash-h-production/releases/#{release_args[:release_id]}")
      .with(headers: default_heroku_headers(user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    stub_request(:post, "#{deployment_url}/statuses")
      .to_return(status: 200, body: {}.to_json, headers: {})

    poller = ReleasePoller.new(release_args)
    lock = Lock.new(poller.release.app.cache_key)
    lock.lock
    poller.run
    expect(lock).to be_locked
  end
  # rubocop:enable Metrics/LineLength
end
