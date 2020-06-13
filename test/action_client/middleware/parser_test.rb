require "test_helper"

module ActionClient
  module Middleware
    class ParserTest < ActiveSupport::TestCase
      test "#call can decode arbitrary content types" do
        payload = "response"
        app = build_app(Rack::CONTENT_TYPE => "text/plain")
        middleware = ActionClient::Middleware::Parser.new app,
          parsers: { "text/plain": -> (body) { body.upcase } }

        _, _, body = middleware.call(Rack::RACK_INPUT => payload.lines)

        assert_equal("RESPONSE", body)
      end

      test "#call can handle errors from an arbitrary content type" do
        app = build_app(Rack::CONTENT_TYPE => "text/plain")
        payload = "response"
        error_response = [422, { "X-Header" => "whoops" }, "error"]
        middleware = ActionClient::Middleware::Parser.new(
          app,
          parsers: {
            "text/plain": -> (body) { raise "whoops" }
          },
          error_handlers: {
            "text/plain": -> (error, type) {
              [422, {"Content-Type" => type}, error.message]
            },
          },
        )

        status, headers, body = middleware.call(Rack::RACK_INPUT => payload.lines)

        assert_equal 422, status
        assert_equal "text/plain", headers["Content-Type"]
        assert_equal "whoops", body
      end

      test "#call decodes application/json to JSON" do
        payload = %({"response": true})
        app = build_app(Rack::CONTENT_TYPE => "application/json")
        middleware = ActionClient::Middleware::Parser.new(app)

        _, _, body = middleware.call(Rack::RACK_INPUT => payload.lines)

        assert_equal({"response" => true}, body)
      end

      test "#call parses JSON into HashWithIndifferentAccess instances" do
        app = build_app(Rack::CONTENT_TYPE => "application/json")
        middleware = ActionClient::Middleware::Parser.new(app)
        payload = %([{ "nested": {"response": true} }])

        _, _, body = middleware.call(Rack::RACK_INPUT => payload.lines)

        assert_equal true, body.first.dig(:nested, :response)
      end

      test "#call recovers from decoding invalid JSON" do
        payload = "junk"
        app = build_app(Rack::CONTENT_TYPE => "application/json")
        middleware = ActionClient::Middleware::Parser.new(app)

        _, _, body = middleware.call(Rack::RACK_INPUT => payload.lines)

        assert_equal("junk", body)
      end

      test "#call decodes application/xml to XML" do
        payload = %(<node id="root"></node>)
        app = build_app(Rack::CONTENT_TYPE => "application/xml")
        middleware = ActionClient::Middleware::Parser.new(app)

        _, _, document = middleware.call(Rack::RACK_INPUT => payload.lines)

        assert_equal "node", document.root.name
        assert_equal "root", document.root["id"]
      end

      test "#call recovers from decoding invalid XML" do
        payload = "junk"
        app = build_app(Rack::CONTENT_TYPE => "application/xml")
        middleware = ActionClient::Middleware::Parser.new(app)

        _, _, document = middleware.call(Rack::RACK_INPUT => payload.lines)

        assert_equal "junk", document
      end

      test "#call does not decode a body without a matching header" do
        payload = "plain-text"
        app = build_app
        middleware = ActionClient::Middleware::Parser.new(app)

        _, _, body = middleware.call(Rack::RACK_INPUT => payload.lines)

        assert_equal payload, body
      end

      def build_app(headers = {})
        proc do |env|
          [ 200, headers, env[Rack::RACK_INPUT] ]
        end
      end
    end
  end
end
