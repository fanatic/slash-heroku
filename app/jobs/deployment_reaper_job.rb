# Job to handle kicking off a Deployment request
class DeploymentReaperJob < ApplicationJob
  queue_as :default

  def perform(args = {})
    DeploymentReaper.new(args).reap
  rescue StandardError => e
    Raven.capture_exception(e)
    Rails.logger.info e.inspect
    Rails.logger.info "ArgList: #{args_list.inspect}"
  end
end
