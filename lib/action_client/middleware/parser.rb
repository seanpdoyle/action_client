module ActionClient
  module Middleware
    class Parser
      JsonParser = proc do |body|
        JSON.parse(body, object_class: HashWithIndifferentAccess)
      end
      XmlParser = proc do |body|
        Nokogiri::XML.parse(body).tap do |document|
          document.validate

          document.errors.each do |error|
            if error.is_a?(Nokogiri::XML::SyntaxError)
              raise error
            end
          end
        end
      end
      NullParser = -> (body) { body }
      NullErrorHandler = -> (_, _, triplet) { triplet }

      class_attribute :parsers, default: {
        "application/json": JsonParser,
        "application/xml": XmlParser,
      }.with_indifferent_access

      class_attribute :error_handlers, default: {
        "application/json": NullErrorHandler,
        "application/xml": NullErrorHandler,
      }.with_indifferent_access

      def initialize(app, configuration = {})
        @app = app
        @parsers = self.class.parsers.merge(configuration.fetch(:parsers, {}))
        @error_handlers = self.class.error_handlers.merge(configuration.fetch(:error_handlers, {}))
        @logger = configuration.fetch(:logger, Rails.logger)
      end

      def call(env)
        status, headers, body_proxy = @app.call(env)
        body = body_proxy.each(&:yield_self).sum
        content_type = headers[Rack::CONTENT_TYPE].to_s

        if body.present?
          parser = fetch_parser_for_content_type(content_type)

          begin
            [ status, headers, parser.call(body) ]
          rescue StandardError => error
            warn(content_type, error)

            error_handler = fetch_error_handler_for_content_type(content_type)

            error_handler_arguments = [ error, content_type, [ status, headers, body ] ]

            error_handler.call(*error_handler_arguments.take(error_handler.arity))
          end
        end
      end

      private

      def warn(content_type, error)
        @logger.warn <<~ERROR.strip
          [#{self.class.name}] Error on #{content_type} : #{error}
        ERROR
      end

      def fetch_error_handler_for_content_type(content_type)
        _, error_handler = @error_handlers.detect do |key, error_handler|
          if content_type.to_s.starts_with?(key.to_s)
            error_handler
          end
        end

        error_handler || NullErrorHandler
      end

      def fetch_parser_for_content_type(content_type)
        _, content_parser = @parsers.detect do |key, parser|
          if content_type.to_s.starts_with?(key.to_s)
            parser
          end
        end

        content_parser || NullParser
      end
    end
  end
end
