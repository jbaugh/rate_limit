module RateLimit
  class Redis < Store
    
    attr_accessor :server

    def initialize(server)
      self.server = server
    end

    def write(key, value, ttl)
      server.setex(key, ttl, value)
    end

    def read(key)
      server.get(key)
    end

    def delete(key)
      server.del(key)
    end
  end
end