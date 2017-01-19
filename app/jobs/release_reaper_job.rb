# Job to handle monitoring a heroku release
class ReleaseReaperJob < ApplicationJob
  queue_as :default

  def perform(args = {})
    ReleaseReaper.reap(args)
  rescue StandardError => e
    Raven.capture_exception(e)
    Rails.logger.info e.inspect
    Rails.logger.info "ArgList: #{args_list.inspect}"
  end
end
