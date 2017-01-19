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

  def self.unlock_deployment(deployment, lock_value)
    new(key(deployment)).unlock(lock_value)
  end

  def self.key(deployment)
    "deployment-lock:#{deployment.application}-#{deployment.environment}"
  end

  def initialize(key)
    @key = key
  end

  def lock
    lock_value = SecureRandom.hex
    locked = redis.set(key, lock_value, nx: true, ex: timeout)
    locked ? lock_value : nil
  end

  def locked?
    redis.exists(key)
  end

  def unlock(lock_value)
    current_lock_value = redis.get(key)
    return if current_lock_value != lock_value
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
