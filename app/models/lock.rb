# Lock with Redis for a period of an hour or until unlock
class Lock
  attr_reader :key

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
