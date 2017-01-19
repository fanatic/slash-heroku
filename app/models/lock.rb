# Lock with Redis for a period of an hour or until unlock
class Lock
  attr_reader :key

  def self.clear_deployment_locks!
    redis = Redis.new
    redis.keys("escobar-app-*").map { |k| redis.del(k) }
  end

  def self.lock_deployment(deployment)
    new(key(deployment)).lock
  end

  def self.unlock_deployment(deployment)
    new(key(deployment)).unlock
  end

  def self.key(deployment)
    "deployment-lock:#{deployment.application}-#{deployment.environment}"
  end

  def initialize(key)
    @key = key
  end

  def lock
    redis.set(key, SecureRandom.hex, nx: true, ex: timeout)
  end

  def locked?
    redis.exists(key)
  end

  def unlock
    redis.del(key)
  end

  private

  def timeout
    1.hour.to_i
  end

  def redis
    @redis ||= Redis.new
  end
end
