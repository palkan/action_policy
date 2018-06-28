# frozen_string_literal: true

module ActionPolicy # :nodoc:
  class CacheMiddleware # :nodoc:
    def initialize(app)
      @app = app
    end

    def call(env)
      ActionPolicy::PerThreadCache.clear_all
      result = @app.call(env)
      ActionPolicy::PerThreadCache.clear_all

      result
    end
  end
end
