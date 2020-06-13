module ActionClient
  module Middleware
    class ResponseParser
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body_proxy = @app.call(env)
        body = body_proxy.each(&:yield_self).sum
        content_type = headers[Rack::CONTENT_TYPE].to_s

        if body.present?
          if content_type.starts_with?("application/json")
            body = parse_as_json(body)
          elsif content_type.starts_with?("application/xml")
            body = parse_as_xml(body)
          else
            body
          end
        end

        [ status, headers, body ]
      end

      private

      def parse_as_json(body)
        JSON.parse(body, object_class: HashWithIndifferentAccess)
      rescue JSON::ParserError
        body
      end

      def parse_as_xml(body)
        document = Nokogiri::XML.parse(body)

        document.validate

        if document.errors.none? { |error| error.is_a?(Nokogiri::XML::SyntaxError) }
          document
        else
          body
        end
      end
    end
  end
end
