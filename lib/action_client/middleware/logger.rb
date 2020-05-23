module ActionClient
  module Middleware
    Logger = proc do |request|
      "ActionClient - #{request.request_method} - #{request.original_url}"
    end
  end
end
