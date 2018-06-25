# frozen_string_literal: true

module ActionPolicy # :nodoc:
  class Middleware # :nodoc:
    def initialize(app)
      @app = app
    end

    def call(env)
      ActionPolicy::PerThreadCache.clear_all
      status, headers, response = @app.call(env)
      ActionPolicy::PerThreadCache.clear_all

      [status, headers, response]
    end
  end
end
