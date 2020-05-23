module ActionClient
  module Middleware
    class ResponseParser
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body_proxy = @app.call(env)
        body = body_proxy.each(&:yield_self).sum

        if body.present?
          case headers["Content-Type"].to_s
          when "application/json"
            body = JSON.parse(body)
          when "application/xml"
            body = Nokogiri::XML(body)
          else
            body
          end
        end

        [ status, headers, body ]
      end
    end
  end
end
