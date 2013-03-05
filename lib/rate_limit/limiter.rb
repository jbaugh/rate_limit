module RateLimit
  class Limiter

    attr_accessor :ip, :options, :cache

    def initialize(options={})
      self.options = options
      setup_cache
    end

    def setup_cache
      self.cache = self.options[:cache]
    end

    def reached_limit?(ip)
      self.ip = ip
      return false if self.whitelisted_ip?

      val = self.cache.read(self.cache_key)
      if val
        return true if val == self.class.lockout_value

        attempts = val.to_i + 1
        set_amount(attempts)

        if attempts > self.options[:threshold].to_i
          lockout!
          return true
        end
      else
        set_amount(1)
      end

      return false

    rescue Exception => ex
      puts ex.message
      return true
    end

    def clear!
      puts "Calling clear! for #{self.cache_key}"
      self.cache.del(self.cache_key)
    end
    
    protected
    
    def whitelisted_ip?
      false
    end
    
    def cache_key
      "ip_address#{self.ip}_#{self.options[:controller].to_s}_#{self.options[:action]}_attempt_count"
    end

    def self.lockout_value
      'LOCKED'
    end

    def lockout!
      puts "Calling lockout! for #{self.cache_key}"
      self.cache.write(self.cache_key, self.class.lockout_value, self.options[:lockout_period].to_i)
    end
    
    def set_amount(amount)
      puts "Setting expiration to #{self.options[:interval].to_i}"
      self.cache.write(self.cache_key, amount, self.options[:interval].to_i)
    end
  end
end