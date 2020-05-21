require "net/http"

module ActionClient
  module Adapters
    module Net
      class HttpAdapter
        def call(request)
          ::Net::HTTP.public_send(
            request.method,
            request.uri,
            request.body.to_s,
            request.headers,
          )
        end
      end
    end
  end
end
