require "rails_helper"

RSpec.describe Lock do
  before do
    Redis.new.del("test")
    Lock.clear_deployment_locks!
  end

  it "locks" do
    lock = Lock.new("test")
    lock.lock
    expect(lock).to be_locked
  end

  it "can be unlocked with lock_value" do
    lock = Lock.new("test")
    lock.lock
    expect(lock).to be_locked
    lock.unlock
    expect(lock).to_not be_locked
  end

  it "can't lock twice" do
    lock = Lock.new("test")
    expect(lock.lock).to be_truthy
    expect(lock.lock).to be_falsey
  end

  it "is unlocked after an hour" do
    lock = Lock.new("test")
    lock.lock
    expect(lock).to be_locked
    # We expect this to run in less than a second.
    expect(Redis.new.ttl("test").to_i).to be >= 3599
    expect(Redis.new.ttl("test").to_i).to be <= 3600
  end

  it "is lockable again after expiration" do
    lock = Lock.new("test")
    lock.lock
    expect(lock).to be_locked
    Redis.new.expire("test", 1)
    sleep(1)
    expect(lock).to_not be_locked
    expect(lock.lock).to be_truthy
  end

  it "locks for a deployment" do
    expect do
      Lock.lock_deployment(Deployment.new)
    end.to change { Redis.new.keys("deployment-lock:*").size }.by(1)
  end

  it "unlocks for a deployment" do
    deployment = Deployment.new
    Lock.lock_deployment(deployment)
    expect do
      Lock.unlock_deployment(deployment)
    end.to change { Redis.new.keys("deployment-lock:*").size }.by(-1)
  end
end
