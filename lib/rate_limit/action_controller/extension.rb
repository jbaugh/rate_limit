module RateLimit
  module ActionController
    module Extension

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
      end

      # USAGE:
      # limit :index, :to => 10, :within => 60

      module ClassMethods
        def limit(action, options={})
          raise 'number of requests (:to) must be specified' unless options[:to].present?
          raise 'rate limit interval (:within) must be specified' unless options[:within].present?

          limiter = Rails3Limiter.new
          
          options.each do |opt, val| 
            limiter.config.send("#{opt}=", val)
          end

          config.limiters                = {} unless config.limiters.present?
          config.limiters[action.to_sym] = limiter

          before_filter :rate_limit_filter, :only => action
        end
      end

      module InstanceMethods
        def rate_limit_filter
          limiter = config.limiters[params[:action].to_sym]
          rate_limit_reached! if limiter.present? && limiter.reached_limit?(*rate_limit_args)
        end

        def rate_limit_args
          return params[:controller], params[:action], request.method, request.remote_ip
        end

        def rate_limit_reached!
          render :text => 'Too Many Requests', :status => 400
        end
      end

    end
  end
end

ActionController::Base.send :include, RateLimit::ActionController::Extension