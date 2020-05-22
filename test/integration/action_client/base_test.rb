require "test_helper"
require "integration_test_case"

module ActionClient
  class ClientTestCase < ActionClient::IntegrationTestCase
    Article = Struct.new(:id, :title)

    class BaseClient < ActionClient::Base
      default url: "https://example.com"
    end
  end

  class RequestsTest < ClientTestCase
    test "constructs a POST request with a JSON body declared with instance variables" do
      class ArticleClient < BaseClient
        def create(article:)
          @article = article

          post path: "/articles"
        end
      end
      declare_template ArticleClient, "create.json.erb", <<~ERB
        <%= { title: @article.title }.to_json %>
      ERB
      article = Article.new(nil, "Article Title")

      request = ArticleClient.create(article: article)

      assert_equal "POST", request.method
      assert_equal "https://example.com/articles", request.original_url
      assert_equal({ "title" => "Article Title" }, JSON.parse(request.body.read))
      assert_equal "application/json", request.headers["Content-Type"]
    end

    test "constructs a GET request without declaring a body template" do
      class ArticleClient < BaseClient
        default headers: { "Content-Type": "application/json" }

        def all
          get path: "/articles"
        end
      end

      request = ArticleClient.all

      assert_equal "GET", request.method
      assert_equal "https://example.com/articles", request.original_url
      assert_predicate request.body.read, :blank?
      assert_equal "application/json", request.headers["Content-Type"]
    end

    test "constructs a DELETE request without declaring a body template" do
      class ArticleClient < BaseClient
        default headers: {
          "Content-Type": "application/json",
        }

        def destroy(article:)
          delete path: "/articles/#{article.id}"
        end
      end
      article = Article.new("1", nil)

      request = ArticleClient.destroy(article: article)

      assert_equal "DELETE", request.method
      assert_equal "https://example.com/articles/1", request.original_url
      assert_predicate request.body.read, :blank?
      assert_equal "application/json", request.headers["Content-Type"]
    end

    test "constructs a DELETE request with a JSON body template" do
      class ArticleClient < BaseClient
        def destroy(article:)
          delete path: "/articles/#{article.id}"
        end
      end
      article = Article.new("1", nil)
      declare_template ArticleClient, "destroy.json", <<~JS
      {"confirm": true}
      JS

      request = ArticleClient.destroy(article: article)

      assert_equal "DELETE", request.method
      assert_equal "https://example.com/articles/1", request.original_url
      assert_equal({ "confirm"=> true }, JSON.parse(request.body.read))
      assert_equal "application/json", request.headers["Content-Type"]
    end

    test "constructs a PUT request with a JSON body declared with locals" do
      class ArticleClient < BaseClient
        def update(article:)
          put path: "/articles/#{article.id}", locals: {
            article: article,
          }
        end
      end
      declare_template ArticleClient, "update.json.erb", <<~ERB
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
      class ArticleClient < BaseClient
        def update(article:)
          patch path: "/articles/#{article.id}", locals: {
            article: article,
          }
        end
      end
      declare_template ArticleClient, "update.xml.erb", <<~ERB
        <xml><%= article.title %></xml>
      ERB
      article = Article.new("1", "Article Title")

      request = ArticleClient.update(article: article)

      assert_equal "PATCH", request.method
      assert_equal "https://example.com/articles/1", request.original_url
      assert_equal "<xml>Article Title</xml>", request.body.read.strip
      assert_equal "application/xml", request.headers["Content-Type"]
    end
  end

  class ResponsesTest < ClientTestCase
    test "#submit makes an appropriate HTTP request" do
      class ArticleClient < BaseClient
        def create(article:)
          post path: "/articles", locals: { article: article }
        end
      end
      declare_template ArticleClient, "create.json.erb", <<~ERB
      <%= { title: article.title }.to_json %>
      ERB
      article = Article.new(nil, "Article Title")
      stub_request(:any, Regexp.new("example.com")).and_return(
        body: %({"responded": true}),
        status: 201,
      )

      code, headers, body = ArticleClient.create(article: article).submit

      assert_equal code, "201"
      assert_equal body, {"responded" => true}
      assert_requested :post, "https://example.com/articles", {
        body: {"title": "Article Title"},
        headers: { "Content-Type" => "application/json" },
      }
    end

    test "#submit parses a JSON response based on the `Content-Type`" do
      class ArticleClient < BaseClient
        def create(article:)
          post path: "/articles", locals: { article: article }
        end
      end
      declare_template ArticleClient, "create.json.erb", <<~ERB
      {"title": "<%= article.title %>"}
      ERB
      article = Article.new(nil, "Encoded as JSON")
      stub_request(:post, %r{example.com}).and_return(
        body: {"title": article.title, id: 1}.to_json,
        headers: {"Content-Type": "application/json"},
        status: 201,
      )

      status, headers, body = ArticleClient.create(article: article).submit

      assert_equal "201", status
      assert_equal "application/json", headers["Content-Type"]
      assert_equal({"title" => article.title, "id" => 1}, body)
    end

    test "#submit parses an XML response based on the `Content-Type`" do
      class ArticleClient < BaseClient
        def create(article:)
          post path: "/articles", locals: { article: article }
        end
      end
      declare_template ArticleClient, "create.xml.erb", <<~ERB
      <article title="<%= article.title %>"></article>
      ERB
      article = Article.new(nil, "Encoded as XML")
      stub_request(:post, %r{example.com}).and_return(
        body: %(<article title="#{article.title}" id="1"></article>),
        headers: {"Content-Type": "application/xml"},
        status: 201,
      )

      status, headers, body = ArticleClient.create(article: article).submit

      assert_equal "201", status
      assert_equal "application/xml", headers["Content-Type"]
      assert_equal article.title, body.root["title"]
      assert_equal "1", body.root["id"]
    end
  end
end
