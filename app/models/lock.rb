# Lock with Redis for a period of an hour or until unlock
class Lock
  attr_reader :key

  def self.redis
    @redis ||= Redis.new
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
    self.class.redis
  end
end
