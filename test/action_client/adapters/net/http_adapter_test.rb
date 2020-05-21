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
          request = ActionDispatch::Request.new({
            Rack::RACK_URL_SCHEME => uri.scheme,
            Rack::HTTP_HOST => uri.hostname,
            Rack::REQUEST_METHOD => "POST",
            "ORIGINAL_FULLPATH" => uri.path,
            "RAW_POST_DATA" => %({"requested": true})
          })
          request.headers["Content-Type"] = "application/json"
          adapter = ActionClient::Adapters::Net::HttpAdapter.new

          response = adapter.call(request)

          assert_equal %({"responded": true}), response.body
          assert_equal "201", response.code
          assert_requested :post, uri, {
            body: %({"requested": true}),
            headers: {
              "Content-Type" => "application/json",
            },
          }
        end
      end
    end
  end
end
