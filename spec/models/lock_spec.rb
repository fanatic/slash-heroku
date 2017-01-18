require "rails_helper"

RSpec.describe Lock do
  before do
    Redis.new.del("test")
    Lock.clear_deployment_locks!
  end

  it "locks" do
    l = Lock.new("test")
    l.lock
    expect(l).to be_locked
  end

  it "can be unlocked with lock_value" do
    l = Lock.new("test")
    lock_value = l.lock
    expect(l).to be_locked
    l.unlock(lock_value)
    expect(l).to_not be_locked
  end

  it "can't lock twice" do
    l = Lock.new("test")
    expect(l.lock).to_not be_nil
    expect(l.lock).to be_nil
  end

  it "is unlocked after an hour" do
    l = Lock.new("test")
    l.lock
    expect(l).to be_locked
    # We expect this to run in less than a second.
    expect(Redis.new.ttl("test").to_i).to be >= 3599
    expect(Redis.new.ttl("test").to_i).to be <= 3600
  end

  it "is lockable again after expiration" do
    l = Lock.new("test")
    l.lock
    expect(l).to be_locked
    Redis.new.expire("test", 1)
    sleep(1)
    expect(l).to_not be_locked
    expect(l.lock).to_not be_nil
  end

  it "locks for a deployment" do
    expect do
      Lock.lock_deployment(Deployment.new)
    end.to change { Redis.new.keys("deployment-lock:*").size }.by(1)
  end

  it "unlocks for a deployment" do
    d = Deployment.new
    value = Lock.lock_deployment(d)
    expect do
      Lock.unlock_deployment(d, value)
    end.to change { Redis.new.keys("deployment-lock:*").size }.by(-1)
  end
end
