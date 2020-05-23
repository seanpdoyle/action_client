module ActionClient
  module Middleware
    class ResponseBody
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)

        [
          status,
          headers,
          body.each(&:yield_self).sum,
        ]
      end
    end
  end
end
