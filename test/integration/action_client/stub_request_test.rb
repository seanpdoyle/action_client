require "test_helper"
require "integration_test_case"

module ActionClient
  class StubRequestTest < IntegrationTestCase
    include ActionClient::TestHelpers

    test "declares WebMock request stub" do
      client = declare_client("articles_client") {
        def create(title, published: true)
          post url: "https://example.com/articles", locals: {
            title: title,
            published: published
          }
        end
      }
      declare_template "articles_client/create.json.erb", <<~ERB
        <%= { title: title, published: published }.to_json %>
      ERB

      stub_request(client.create("Hello, World", published: true)).to_return(
        status: 200,
        headers: {"Content-Type": "application/json"},
        body: {status: "stubbed"}.to_json
      )
      status, headers, body = *client.create("Hello, World", published: true).submit

      assert_requested :post, "https://example.com/articles",
        headers: {"Content-Type": "application/json"},
        body: {title: "Hello, World", published: true}.to_json,
        times: 1
      assert_equal 200, status
      assert_equal "application/json", headers["Content-Type"]
      assert_equal "stubbed", body.fetch("status")
    end

    test "determines request and response Content-Type based on the request headers" do
      client = declare_client {
        def all
          get url: "https://example.com/articles", headers: {
            "Accept": "application/json",
            "Content-Type": "application/json"
          }
        end
      }

      stub_request(client.all).to_return(status: 200)
      response = client.all.submit

      assert_requested :get, "https://example.com/articles",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
        times: 1
      assert_equal 200, response.status
      assert_equal "application/json", response.headers["Content-Type"]
    end

    test "falls back to WebMock" do
      client = declare_client("articles_client") {
        def create(title:)
          post url: "https://example.com/articles", locals: {title: title}
        end
      }
      declare_template "articles_client/create.json.erb", <<~ERB
        <%= { title: title }.to_json %>
      ERB

      stub_request(:post, "https://example.com/articles").to_return(
        status: 200,
        body: {status: "stubbed"}.to_json,
        headers: {"Content-Type": "application/json"}
      )

      client.create(title: "Hello, World").submit

      assert_requested :post, "https://example.com/articles",
        headers: {"Content-Type": "application/json"},
        body: {title: "Hello, World"}.to_json,
        times: 1
    end

    test "declares WebMock request stub with its body generated by a fixture" do
      client = declare_client("articles_client") {
        def create(title:)
          post url: "https://example.com/articles", locals: {title: title}
        end
      }
      declare_template "articles_client/create.json.erb", <<~ERB
        <%= { title: title }.to_json %>
      ERB
      declare_fixture "articles_client/create.json.erb", <<~ERB
        <%= { status: "stubbed" }.to_json %>
      ERB

      stub_request(client.create(title: "Hello, World")).to_fixture

      status, headers, body = *client.create(title: "Hello, World").submit

      assert_equal 200, status
      assert_equal "application/json", headers["Content-Type"]
      assert_equal "stubbed", body.fetch("status")
    end

    test "incorporates variants when stubbing a request body with a fixture" do
      client = declare_client("articles_client") {
        def create(title:)
          post url: "https://example.com/articles", locals: {title: title}
        end
      }
      declare_template "articles_client/create.json.erb", <<~ERB
        <%= { title: title }.to_json %>
      ERB
      declare_fixture "articles_client/create.json", <<~JS
        {"error": "IGNORED!"}
      JS
      declare_fixture "articles_client/create.json+422.erb", <<~JS
        {"error": "invalid!"}
      JS

      stub_request(client.create(title: "Hello, World")).to_fixture(status: 422)

      response = client.create(title: "Hello, World").submit

      assert_equal 422, response.status
      assert_equal "invalid!", response.body.fetch("error")
    end

    test "falls back to the most general template available" do
      client = declare_client("articles_client") {
        def create(title:)
          post(
            url: "https://example.com/articles", locals: {title: title},
            headers: {"Content-Type": "application/json"}
          )
        end
      }
      declare_fixture "articles_client/create.json", <<~JS
        {"status": "created!"}
      JS

      stub_request(client.create(title: "Hello, World")).to_fixture(status: 200)

      response = client.create(title: "Hello, World").submit

      assert_equal 200, response.status
      assert_equal "created!", response.body.fetch("status")
    end

    test "accepts named status code for a variant" do
      client = declare_client("articles_client") {
        def create(title:)
          post url: "https://example.com/articles", locals: {title: title}
        end
      }
      declare_template "articles_client/create.json.erb", <<~ERB
        <%= { title: title }.to_json %>
      ERB
      declare_fixture "articles_client/create.json+created.erb", <<~JS
        {"status": "created!"}
      JS

      stub_request(client.create(title: "Hello, World")).to_fixture(status: :created)

      response = client.create(title: "Hello, World").submit

      assert_equal 201, response.status
      assert_equal "created!", response.body.fetch("status")
    end

    test "accepts headers as to_fixture arguments" do
      client = declare_client("articles_client") {
        def create
          post url: "https://example.com/articles"
        end
      }
      declare_fixture "articles_client/create.json", <<~JS
        {"status": "created!"}
      JS

      stub_request(client.create).to_fixture(
        headers: {"Content-Type": "application/ld+json"}
      )
      response = client.create.submit

      assert_equal "created!", response.body["status"]
      assert_equal "application/ld+json", response.headers["Content-Type"]
    end

    test "incorporates variants when stubbing a request body with a dynamic fixture" do
      client = declare_client("articles_client") {
        def create(title:)
          post url: "https://example.com/articles", locals: {title: title}
        end
      }
      declare_template "articles_client/create.json.erb", <<~ERB
        <%= { title: title }.to_json %>
      ERB
      declare_fixture "articles_client/create.json+422.erb", <<~ERB
        <%= { error: message }.to_json %>
      ERB

      stub_request(client.create(title: "Hello, World")).to_fixture(
        status: 422,
        locals: {message: "failed!"}
      )
      response = client.create(title: "Hello, World").submit

      assert_equal 422, response.status
      assert_equal "failed!", response.body.fetch("error")
    end

    test "resolves Integer status variants to their Status Name" do
      client = declare_client("articles_client") {
        def create
          post url: "https://example.com/articles"
        end
      }
      declare_fixture "articles_client/create.json+422.erb", <<~ERB
        {"error": "failed!"}
      ERB

      stub_request(client.create).to_fixture(status: :unprocessable_entity)
      response = client.create.submit

      assert_equal 422, response.status
      assert_equal "failed!", response.body.fetch("error")
    end

    test "resolves String status names variants to their Status Code" do
      client = declare_client("articles_client") {
        def create
          post url: "https://example.com/articles"
        end
      }
      declare_fixture "articles_client/create.json+unprocessable_entity.erb", <<~ERB
        {"error": "failed!"}
      ERB

      stub_request(client.create).to_fixture(status: 422)
      response = client.create.submit

      assert_equal 422, response.status
      assert_equal "failed!", response.body.fetch("error")
    end

    test "stubs request with its body generated by a dynamic fixture" do
      client = declare_client("articles_client") {
        def create(title:)
          post url: "https://example.com/articles", locals: {title: title}
        end
      }
      declare_template "articles_client/create.json.erb", <<~ERB
        <%= { title: title }.to_json %>
      ERB
      declare_fixture "articles_client/create.json.erb", <<~ERB
        <%= { status: status }.to_json %>
      ERB

      stub_request(client.create(title: "Hello, World")).to_fixture(
        status: 200,
        locals: {status: "dynamic"}
      )

      response = client.create(title: "Hello, World").submit

      assert_equal "dynamic", response.body.fetch("status")
    end

    test "passes request arguments to fixtures as template-local variables" do
      client = declare_client("articles_client") {
        def create(title:)
          post url: "https://example.com/articles", locals: {title: title}
        end
      }
      declare_template "articles_client/create.json.erb", <<~ERB
        <%= { title: title }.to_json %>
      ERB
      declare_fixture "articles_client/create.json.erb", <<~ERB
        <%= { id: 1, title: options[:title] }.to_json %>
      ERB

      stub_request(client.create(title: "Argument Title")).to_fixture(
        status: 200
      )

      response = client.create(title: "Argument Title").submit

      assert_equal 1, response.body.fetch("id")
      assert_equal "Argument Title", response.body.fetch("title")
    end

    test "merges request arguments with fixtures local variables" do
      client = declare_client("articles_client") {
        def create(kept, overridden:)
          post url: "https://example.com/articles", locals: {
            kept: kept,
            overridden: overridden
          }
        end
      }
      declare_template "articles_client/create.json.erb", <<~ERB
        <%= local_assigns.to_json %>
      ERB
      declare_fixture "articles_client/create.json.erb", <<~ERB
        <%= { kept: arguments.first, overridden: overridden }.to_json %>
      ERB

      stub_request(client.create("kept", overridden: "original")).to_fixture(
        status: 200,
        locals: {overridden: "overridden"}
      )

      response = client.create("kept", overridden: "original").submit

      assert_requested :post, "https://example.com/articles",
        body: {kept: "kept", overridden: "original"}.to_json,
        times: 1
      assert_equal "kept", response.body.fetch("kept")
      assert_equal "overridden", response.body.fetch("overridden")
    end
  end
end
