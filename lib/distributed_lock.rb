require 'redis'
require 'redis-lock'

class DistributedLock
  DEFAULTS = {
    life: (5 * 60), # lifetime (in seconds)
    acquire: 10, # acquisition timeout (in seconds). This is how long a 2nd lock waits if there's a 1st one already
  }

  def initialize(lock_name, options = {})
    @lock_name = lock_name
    @options = DEFAULTS.merge(options)
  end

  def lock
    redis.lock("need-api:#{Rails.env}:#{@lock_name}", @options) do
      Rails.logger.debug('Successfully got a lock. Running...')
      yield
    end
  rescue Redis::Lock::LockNotAcquired => e
    Rails.logger.debug("Failed to get lock for #{@lock_name} (#{e.message}). Another process probably got there first.")
  end

private
  def redis
    @_redis ||= begin
      redis_config = Rails.application.config_for(:redis)
      Redis.new(redis_config.symbolize_keys)
    end
  end
end
