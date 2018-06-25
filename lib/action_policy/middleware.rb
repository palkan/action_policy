module ActionPolicy
	class Middleware
		def initialize app
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