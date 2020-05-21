require "test_helper"
require "integration_test_case"
require "action_client/adapters/null_adapter"

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

    setup do
      ActionClient::Base.default adapter: :null
      ActionClient::Base.adapters[:null] = ActionClient::Adapters::NullAdapter
    end

    test "makes a POST request with a JSON body declared with instance variables" do
      declare_template ArticleClient, "create.json.erb", <<-ERB
        <%= { title: @article.title }.to_json %>
      ERB
      article = Article.new(nil, "Article Title")

      request = ArticleClient.create(article: article)

      assert_equal :post, request.method
      assert_equal "https://example.com/articles", request.url.to_s
      assert_equal({ "title" => "Article Title" }, JSON.parse(request.body))
      assert_equal({ "Content-Type" => "application/json" }, request.headers)
    end

    test "makes a PUT request with a JSON body declared with locals" do
      declare_template ArticleClient, "update.json.erb", <<-ERB
        <%= { title: article.title }.to_json %>
      ERB
      article = Article.new("1", "Article Title")

      request = ArticleClient.update(article: article)

      assert_equal :put, request.method
      assert_equal "https://example.com/articles/1", request.url.to_s
      assert_equal({ "title" => "Article Title" }, JSON.parse(request.body))
      assert_equal({ "Content-Type" => "application/json" }, request.headers)
    end

    test "makes a PATCH request with an XML body declared with locals" do
      declare_template ArticleClient, "update.xml.erb", <<-ERB
        <xml><%= article.title %></xml>
      ERB
      article = Article.new("1", "Article Title")

      request = ArticleClient.update(article: article)

      assert_equal :put, request.method
      assert_equal "https://example.com/articles/1", request.url.to_s
      assert_equal "<xml>Article Title</xml>", request.body.strip
      assert_equal({ "Content-Type" => "application/xml" }, request.headers)
    end
  end
end
