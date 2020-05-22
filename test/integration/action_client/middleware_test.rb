require "test_helper"
require "integration_test_case"
require "rack/content_length"
require "rack/contrib/json_body_parser"

module ActionClient
  class MiddlewareTest < ActionClient::IntegrationTestCase
    class ArticleClient < ActionClient::Base
      default url: "https://example.com"

      def create(title)
        post path: "/articles", locals: { title: title }
      end
    end

    test "#processes requests through a middleware stack" do
      with_middleware_stacks(
        request_middleware: [Rack::ContentLength],
      ) do
        declare_template ArticleClient, "create.json.erb", <<~ERB
        {"title": "<%= title %>"}
        ERB
        title = "Article"

        request = ArticleClient.create(title)

        assert_equal "21", request.env[Rack::CONTENT_LENGTH]
        assert_equal({"title" => title}, JSON.parse(request.body.read))
      end
    end

    test "#processes responses through a middleware stack" do
      with_middleware_stacks(
        response_middleware: [Rack::JSONBodyParser],
      ) do
        declare_template ArticleClient, "create.json.erb", <<~ERB
        {"title": "<%= title %>"}
        ERB
        title = "Encoded as JSON"
        stub_request(:post, %r{example.com}).and_return(
          body: {"title": title, id: 1}.to_json,
          headers: {"Content-Type": "application/json"},
          status: 201,
        )

        status, headers, body = ArticleClient.create(title).submit

        assert_equal "201", status
        assert_equal "application/json", headers["Content-Type"]
        assert_equal({"title" => title, "id" => 1}, body)
      end
    end

    def with_middleware_stacks(middlewares_keyed_by_configuration, &block)
      configuration = Rails.configuration.action_client
      defaults = configuration.slice(middlewares_keyed_by_configuration.keys)

      middlewares_keyed_by_configuration.each do |key, middlewares|
        configuration[key] = ActionDispatch::MiddlewareStack.new do |stack|
          middlewares.each do |middleware|
            stack.use middleware
          end
        end
      end

      block.call
    ensure
      defaults.each do |key, default_middleware_stack|
        Rails.configuration.action_client.middleware = default_middleware_stack
      end
    end
  end
end
