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
    end

    def reached_limit?(controller,action,method,ip)
      return false if whitelisted_ip?(ip)

      key       = cache_key controller, action, method, ip
      attempts  = config.cache.read(key).to_i                 # nil.to_i => 0
      attempts += 1                                           # increment by one

      config.cache.write key, attempts, :expires_in => config.interval.to_i

      attempts <= config.threshold
    rescue => e
      log e.message
      log e.backtrace.join("\n")
      true
    end
    
    protected
    
    # TODO have this work for IP ranges as well, see:
    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/ipaddr/rdoc/IPAddr.html

    def whitelisted_ip?(ip)
      config.allowed_ips.include?(ip)
    end
    
    def cache_key(controller,action,method,ip)
      request = "#{controller}##{action}"
      request = "#{method.upcase}_#{request}" if config.limit_by_method
      "rate_limit/requests/#{ip}/#{request}"
    end

  end
end