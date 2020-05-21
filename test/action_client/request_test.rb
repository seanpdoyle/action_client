require "test_helper"

module ActionClient
  class RequestTest < ActiveSupport::TestCase
    test "#submit sends a POST request" do
      uri = URI("https://www.example.com/articles")
      request = ActionClient::Request.new(
        body: "{}",
        method: :post,
        uri: uri.to_s,
        headers: {
          "Content-Type": "application/json",
        }
      )
      stub_request(:any, Regexp.new(uri.hostname)).and_return(body: "{}")

      request.submit

      assert_requested :post, uri, {
        body: "{}",
        headers: request.headers,
      }
    end
  end
end
