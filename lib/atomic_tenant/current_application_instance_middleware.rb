module AtomicTenant
  class CurrentApplicationInstanceMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if env['atomic.validated.oauth_consumer_key'].present?
        oauth_consumer_key = env['atomic.validated.oauth_consumer_key']
        if ai = ApplicationInstance.find_by(lti_key: oauth_consumer_key)
          env['atomic.validated.application_instance_id'] = ai.id
        end
      end

      @app.call(env)
    end
  end
end
