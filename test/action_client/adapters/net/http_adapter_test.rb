require "test_helper"

module ActionClient
  module Adapters
    module Net
      class HttpAdapterTest < ActiveSupport::TestCase
        test "#submit sends a POST request" do
          uri = URI("https://www.example.com/articles")
          stub_request(:any, Regexp.new(uri.hostname)).and_return(
            body: %({"responded": true}),
            status: 201,
          )
          request = ActionClient::Request.new(
            body: %({"requested": true}),
            method: :post,
            uri: uri.to_s,
            headers: {
              "Content-Type": "application/json",
            }
          )
          adapter = ActionClient::Adapters::Net::HttpAdapter.new

          response = adapter.call(request)

          assert_equal %({"responded": true}), response.body
          assert_equal "201", response.code
          assert_requested :post, uri, {
            body: %({"requested": true}),
            headers: request.headers,
          }
        end
      end
    end
  end
end
