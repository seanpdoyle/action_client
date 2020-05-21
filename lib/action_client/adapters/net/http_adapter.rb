require "net/http"

module ActionClient
  module Adapters
    module Net
      class HttpAdapter
        def call(request)
          method = request.request_method.to_s.downcase

          ::Net::HTTP.public_send(
            method,
            URI(request.original_url),
            request.body.read,
            ActionClient::Utils.headers_to_hash(request.headers),
          )
        end
      end
    end
  end
end
