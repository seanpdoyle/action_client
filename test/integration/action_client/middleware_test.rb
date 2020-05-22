require "test_helper"
require "integration_test_case"
require "rack/content_length"

module ActionClient
  class MiddlewareTest < ActionClient::IntegrationTestCase
    class ArticleClient < ActionClient::Base
      default url: "https://example.com"

      def create(title)
        post path: "/articles", locals: { title: title }
      end
    end

    test "#processes requests through the middleware stack" do
      with_request_middleware_stack([
        Rack::ContentLength
      ]) do
        declare_template ArticleClient, "create.json.erb", <<~ERB
        {"title": "<%= title %>"}
        ERB
        title = "Article"

        request = ArticleClient.create(title)

        assert_equal "21", request.env[Rack::CONTENT_LENGTH]
      end
    end

    def with_request_middleware_stack(middlewares, &block)
      configuration = Rails.configuration.action_client
      default_middleware_stack = configuration.middleware

      configuration.middleware = ActionDispatch::MiddlewareStack.new do |stack|
        middlewares.each do |middleware|
          stack.use middleware
        end
      end

      block.call
    ensure
      Rails.configuration.action_client.middleware = default_middleware_stack
    end
  end
end
