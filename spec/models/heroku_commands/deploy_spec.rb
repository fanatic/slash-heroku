require "rails_helper"

RSpec.describe HerokuCommands::Deploy, type: :model do
  include Helpers::Command::Deploy

  before do
    Lock.clear_deploy_locks!
  end

  def build_command(cmd)
    command = command_for(cmd)
    user = command.user
    user.github_token = Digest::SHA1.hexdigest(Time.now.utc.to_f.to_s)
    user.save
    command.user.reload
    command
  end

  def stub_pipelines(pipelines)
    pipelines = pipelines.is_a?(Array) ? pipelines : [pipelines]
    stub_json_request(:get,
                      "https://api.heroku.com/pipelines",
                      pipelines.to_json)
  end

  def stub_couplings(pipeline_id, apps, stage = "production")
    apps = apps.is_a?(Array) ? apps : [apps]
    couplings = apps.map do |app|
      { stage: stage, app: { id: app[:id] }}
    end
    stub_json_request(:get,
                      "https://api.heroku.com/pipelines/#{pipeline_id}/pipeline-couplings",
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
    stub_json_request(:get,
                      "https://kolkrabbi.com/pipelines/#{pipeline_id}/repository",
                      { repository: { name: repo_name_with_owner }}.to_json)
  end

  def stub_repository(name_with_owner, default_branch = "master")
    stub_json_request(:get,
                      "https://api.github.com/repos/#{name_with_owner}",
                      { default_branch: default_branch }.to_json)
  end

  def stub_required_contexts(name_with_owner, branch = "master")
    stub_json_request(:get,
                      "https://api.github.com/repos/#{name_with_owner}/branches/#{branch}",
                      {}.to_json)
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

  def stub_2fa_locked_app_flow(pipeline_name, app_name)
    pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
    app = { id: SecureRandom.uuid, name: app_name }

    stub_pipelines(pipeline)
    stub_couplings(pipeline[:id], app)
    stub_heroku_app(app[:id], app[:name])
    stub_2fa_check(app[:id], locked: true)
  end

  def stub_locked_deployment_flow(pipeline_name, app_name)
    pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
    app = { id: SecureRandom.uuid, name: app_name }

    stub_pipelines(pipeline)
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

    pipeline =  { id: SecureRandom.uuid, name: pipeline_name }
    apps = app_names.map do |app_name|
      { id: SecureRandom.uuid, name: app_name }
    end

    stub_pipelines(pipeline)
    stub_couplings(pipeline[:id], apps)
    apps.each do |app|
      stub_heroku_app(app[:id], app[:name])
    end

    if chosen_app_name
      chosen_app = apps.detect { |app| app[:name] == chosen_app_name }
      stub_2fa_check(chosen_app[:id])
      stub_mapping_pipeline_repository(pipeline[:id], repo)

      stub_repository(repo)
      stub_required_contexts(repo)
      stub_deployment_status(repo)
    end
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

  # rubocop:disable Metrics/LineLength
  it "has a deploy command" do
    command = build_command("deploy hubot to production")

    stub_successful_deployment_flow("hubot")

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response).to be_empty
  end

  it "responds to you if required commit statuses aren't present" do
    command = build_command("deploy hubot to production")

    pipeline_name = "hubot"
    app_name = "hubot1"
    repo = "atmos/hubot"

    stub_missing_required_commit_status_flow(pipeline_name, app_name, repo)

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response[:response_type]).to eql("in_channel")
    expect(response[:text]).to be_nil
    expect(response[:attachments].size).to eql(1)
    attachment = response[:attachments].first
    expect(attachment[:text]).to eql(
      "Unable to create GitHub deployments for atmos/hubot: " \
      "Conflict: Commit status checks failed for master."
    )
  end

  it "prompts to unlock in the dashboard if the app is 2fa protected" do
    command = build_command("deploy hubot to production")

    pipeline_name = "hubot"
    app_name = "hubot1"

    stub_2fa_locked_app_flow(pipeline_name, app_name)

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response[:text]).to be_nil
    expect(response[:response_type]).to be_nil
    attachments = [
      { text: "<https://dashboard.heroku.com/apps/hubot1|Unlock hubot1>" }
    ]
    expect(response[:attachments]).to eql(attachments)
  end

  it "locks on second attempt" do
    command = command_for("deploy hubot to production")
    heroku_command = HerokuCommands::Deploy.new(command)
    heroku_command.user.github_token = SecureRandom.hex
    heroku_command.user.save

    pipeline_name = "hubot"
    app_name = "hubot1"

    stub_locked_deployment_flow(pipeline_name, app_name)

    response = heroku_command.run

    attachments = [
      {
        text: "Someone is already deploying to hubot1",
        color: "#f00"
      }
    ]
    expect(response[:attachments]).to eql(attachments)
  end

  it "responds with an error message if the pipeline contains more than one app" do
    command = build_command("deploy hubot to production")

    stub_multiple_apps_in_stage_flow(
      pipeline_name: "hubot",
      app_names: ["hubot1", "hubot2"]
    )

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    attachments = [
      {
        text: "There is more than one app in the hubot production stage: hubot1, hubot2. This is not supported yet.",
        color: "#f00"
      }
    ]
    expect(response[:attachments]).to eql(attachments)
  end

  it "deploys an application if the pipeline has multiple apps and an app is specified" do
    command = build_command("deploy hubot to production/hubot1")

    stub_multiple_apps_in_stage_flow(
      pipeline_name: "hubot",
      app_names: ["hubot1", "hubot2"],
      chosen_app_name: "hubot1",
      repo: "atmos/hubot"
    )

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")

    heroku_command = HerokuCommands::Deploy.new(command)

    response = heroku_command.run

    expect(heroku_command.pipeline_name).to eql("hubot")
    expect(response).to be_empty
  end
end
