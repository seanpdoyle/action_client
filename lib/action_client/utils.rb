module ActionClient
  class Utils
    def self.headers_to_hash(rack_headers)
      rack_headers.reduce({}) do |rewritten_headers, (key, value)|
        if key.starts_with?("HTTP_") || ActionDispatch::Http::Headers::CGI_VARIABLES.include?(key)
          rewritten_headers[key.sub(%r{\AHTTP_}, "").titleize.gsub(" ", "-")] = value
        end

        rewritten_headers
      end
    end
  end
end
