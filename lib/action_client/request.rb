module ActionClient
  class Request
    attr_reader :body
    attr_reader :headers
    attr_reader :method
    attr_reader :uri

    alias_method :url, :uri

    def initialize(body:, method:, uri:, headers: {})
      @body = body
      @method = method
      @uri = URI(uri)
      @headers = headers.to_h.stringify_keys
    end

    def submit
      response = Net::HTTP.start(@uri.hostname, @uri.port) do |http|
        case @method
        when :post
          Net::HTTP.post(@uri, @body.to_s, @headers)
        end
      end

      JSON.parse(response.body)
    end
  end
end
