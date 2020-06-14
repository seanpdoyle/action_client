module ActionClient
  class HttpStatusFilter
    def initialize(http_status)
      @http_status = http_status
    end

    def include?(matching_status)
      status_codes.include? to_code(matching_status)
    end

    private

    attr_reader :http_status

    def status_codes
      case http_status
      when nil
        100..599
      when Range
        http_status
      else
        Array(http_status).map { |status| to_code(status) }
      end
    end

    def to_code(status)
      Rack::Utils.status_code(status)
    end
  end
end
