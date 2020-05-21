require "test_helper"

module ActionClient
  class RequestTest < ActiveSupport::TestCase
    test "#submit sends a POST request" do
      uri = URI("https://www.example.com/articles")
      request = ActionClient::Request.new(
        body: %({"requested": true}),
        method: :post,
        uri: uri.to_s,
        headers: {
          "Content-Type": "application/json",
        }
      )
      stub_request(:any, Regexp.new(uri.hostname)).and_return(
        body: %({"responded": true}),
        status: 201,
      )

      response = request.submit

      assert_equal %({"responded": true}), response.body
      assert_equal "201", response.code
      assert_requested :post, uri, {
        body: %({"requested": true}),
        headers: request.headers,
      }
    end
  end
end
