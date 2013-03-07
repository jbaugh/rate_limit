module RateLimit
  module ActionController
    module Extension

      # USAGE:
      # limit :index, :to => 10, :within => 60

      def self.limit(action,options={})
        # uncommment to force explicit settings
        # raise 'number of requests (:to) must be specified' unless options[:to].present?
        # raise 'rate limit interval (:within) must be specified' unless options[:within].present?

        limiter = Rails3Limiter.new
        limiter.config.threshold = options[:to] if options[:to].present?
        limiter.config.interval  = options[:within] if options[:within].present?

        options.slice(options.keys-[:to,:within]).each { |o| limiter.config.send "#{o}=", options[o] }

        config.limiters                = {} unless config.limiters.present?
        config.limiters[action.to_sym] = limiter

        before_filter :rate_limit_filter, :only => action
      end

      def rate_limit_filter
        limiter = config.limiters[params[:action].to_sym]
        rate_limit_reached! if limiter.present? && limiter.reached_limit?(*rate_limit_args)
      end

      def rate_limit_args
        params[:controller], params[:action], request.method, request.remote_ip
      end

      def rate_limit_reached!
        render :text => 'Too Many Requests', :status => 400
      end

    end
  end
end

# extend ActionController
ActionController::Base.include RateLimit::ActionController::Extension