module ActionClient
  module Middleware
    class BodyParser
      def initialize(app)
        @app = app
      end

      def call(env)
        require "irb"; ::Kernel.binding.irb
        @app.call(env)
      end
    end
  end
end
