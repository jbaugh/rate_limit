if defined?(Rails) && Rails.version > '3.0'
  # if in Rails context, use Rails.cache as the store
  # additionally, hook into ActionController for
  # the actual rate limiting
  require 'rate_limit/rails_3_limiter'
  require 'rate_limit/action_controller/extension'
else
  require 'rate_limit/store'
  require 'rate_limit/store/redis'
  require 'rate_limit/store/memcache'
  require 'rate_limit/rate_binding'
  require 'rate_limit/limiter'
end