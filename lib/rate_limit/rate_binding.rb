
"""

require 'rate_limit'
require 'redis-store'
server = Redis.new(:host => '127.0.0.1', :port => '6379')
cache = RateLimit::Redis.new(server)

RateLimit::RateBinding.new({
  :action => :index, 
  :controller => PagesController,
  :threshold => 10,
  :interval => 60,
  :lockout_period => 60,
  :cache => cache
})

"""

module RateLimit
  class RateBinding

    attr_accessor :options, :rate_limit

    def self.required_options
      [:controller, :action, :threshold, :interval, :lockout_period, :cache]
    end

    def initialize(options={})
      self.options = options
      check_required_options!
      self.rate_limit = RateLimit::Limiter.new(self.options)
      setup_callback
    end

    def setup_callback
      self.options[:controller].instance_exec(self) do |rate_binding|
        define_method("check_rate_limit_#{rate_binding.options[:action]}") do 
          puts "Reached limit?: #{!!rate_binding.rate_limit.reached_limit?(request.remote_ip)}"
        end
      end

      if self.options[:controller].respond_to?(:before_filter)
        self.options[:controller].before_filter("check_rate_limit_#{self.options[:action]}".to_sym, :only => self.options[:action].to_sym)
      else
        raise "Could not setup before_filter for #{self.options[:controller].to_s}::#{self.options[:action]}"
      end
    end

    def check_required_options!
      RateBinding.required_options.each do |opt|
        raise "Required option (symbol): #{opt.to_s}" unless self.options[opt]
      end
    end
  end
end