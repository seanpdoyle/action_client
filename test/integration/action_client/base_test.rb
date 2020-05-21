require "test_helper"
require "integration_test_case"
require "action_client/engine"

module ActionClient
  class BaseTest < ActionClient::IntegrationTestCase
    Article = Struct.new(:id, :title)

    class ArticleClient < ActionClient::Base
      default url: "https://example.com"

      def create(article:)
        @article = article

        post path: "/articles"
      end

      def update(article:)
        put path: "/articles/#{article.id}", locals: {
          article: article,
        }
      end
    end

    test "constructs a POST request with a JSON body declared with instance variables" do
      declare_template ArticleClient, "create.json.erb", <<-ERB
        <%= { title: @article.title }.to_json %>
      ERB
      article = Article.new(nil, "Article Title")

      request = ArticleClient.create(article: article)

      assert_equal "POST", request.method
      assert_equal "https://example.com/articles", request.original_url
      assert_equal({ "title" => "Article Title" }, JSON.parse(request.body.read))
      assert_equal "application/json", request.headers["Content-Type"]
    end

    test "constructs a PUT request with a JSON body declared with locals" do
      declare_template ArticleClient, "update.json.erb", <<-ERB
        <%= { title: article.title }.to_json %>
      ERB
      article = Article.new("1", "Article Title")

      request = ArticleClient.update(article: article)

      assert_equal "PUT", request.method
      assert_equal "https://example.com/articles/1", request.original_url
      assert_equal({ "title" => "Article Title" }, JSON.parse(request.body.read))
      assert_equal "application/json", request.headers["Content-Type"]
    end

    test "constructs a PATCH request with an XML body declared with locals" do
      declare_template ArticleClient, "update.xml.erb", <<-ERB
        <xml><%= article.title %></xml>
      ERB
      article = Article.new("1", "Article Title")

      request = ArticleClient.update(article: article)

      assert_equal "PUT", request.method
      assert_equal "https://example.com/articles/1", request.original_url
      assert_equal "<xml>Article Title</xml>", request.body.read.strip
      assert_equal "application/xml", request.headers["Content-Type"]
    end

    test "#submit makes an appropriate HTTP request" do
      stub_request(:any, Regexp.new("example.com")).and_return(
        body: %({"responded": true}),
        status: 201,
      )

      declare_template ArticleClient, "create.json.erb", <<-ERB
      <%= { title: @article.title }.to_json %>
      ERB
      article = Article.new(nil, "Article Title")

      response = ArticleClient.create(article: article).submit

      assert_equal response.code, "201"
      assert_equal response.body, %({"responded": true})
      assert_requested :post, "https://example.com/articles", {
        body: {"title": "Article Title"},
        headers: { "Content-Type" => "application/json" },
      }
    end
  end
end
