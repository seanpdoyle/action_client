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
          payload = %({"requested": true})
          adapter = ActionClient::Adapters::Net::HttpAdapter.new

          code, headers, body = adapter.call(
            Rack::RACK_URL_SCHEME => uri.scheme,
            Rack::HTTP_HOST => uri.hostname,
            Rack::REQUEST_METHOD => "POST",
            "ORIGINAL_FULLPATH" => uri.path,
            "RAW_POST_DATA" => payload,
            Rack::RACK_INPUT => StringIO.new(payload),
            "CONTENT_TYPE" => "application/json",
          )

          assert_equal %({"responded": true}), body
          assert_equal "201", code
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
