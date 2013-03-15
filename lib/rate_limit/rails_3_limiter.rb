module RateLimit
  class Rails3Limiter
    include ActiveSupport::Configurable

    config.ip              = nil
    config.cache           = nil
    config.threshold       = 10
    config.interval        = 60
    config.lockout_period  = 60
    config.allowed_ips     = []
    config.limit_by_method = false

    def initialize
      config.cache = Rails.cache unless config.cache.present?
      config.logger = Rails.logger unless config.logger.present?
    end

    def reached_limit?(controller, action, method, ip)
      return false if whitelisted_ip?(ip)

      key       = cache_key(controller, action, method, ip)
      attempts  = config.cache.read(key).to_i                 # nil.to_i => 0
      attempts += 1                                           # increment by one

      config.cache.write(key, attempts, :expires_in => config.interval.to_i)

      if attempts > config.threshold
        lockout!
        true
      else
        false
      end
    rescue => e
      config.logger.info e.message
      config.logger.info e.backtrace.join("\n")
      true
    end

    def clear!
      config.logger.info "Calling clear! for #{self.cache_key}"
      config.cache.delete(self.cache_key)
    end
    
    protected

    def self.lockout_value
      'LOCKED'
    end

    def lockout!
      config.logger.info "Calling lockout! for #{self.cache_key}"
      config.cache.write(self.cache_key, self.class.lockout_value, config.lockout_period)
    end
    
    # TODO have this work for IP ranges as well, see:
    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/ipaddr/rdoc/IPAddr.html
    def whitelisted_ip?(ip)
      config.allowed_ips.include?(ip)
    end
    
    def cache_key(controller, action, method, ip)
      request = "#{controller}##{action}"
      request = "#{method.upcase}_#{request}" if config.limit_by_method
      "rate_limit/requests/#{ip}/#{request}"
    end

  end
end