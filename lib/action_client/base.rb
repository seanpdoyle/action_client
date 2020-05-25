module ActionClient
  class Base < AbstractController::Base
    abstract!

    include AbstractController::Rendering
    include ActionView::Layouts

    cattr_accessor :defaults,
      instance_accessor: true,
      default: ActiveSupport::OrderedOptions.new

    class << self
      alias_method :client_name, :controller_path

      def default(options)
        options.each do |key, value|
          defaults[key] = value
        end
      end

      def method_missing(method_name, *args)
        if action_methods.include?(method_name.to_s)
          self.new.process(method_name, *args)
        else
          super
        end
      end
    end

    def build_request(method:, path: nil, url: nil, headers: {}, **options)
      if path.present? && url.present?
        raise ArgumentError, "either pass only url:, or only path:"
      end

      uri = URI(url || defaults.url)

      if path.present?
        uri = URI(File.join(uri.to_s, path.to_s))
      end

      headers = headers.to_h.with_defaults(defaults.headers.to_h)

      begin
        template_path = self.class.client_name
        template_name = action_name
        template = lookup_context.find(template_name, Array(template_path))
        format = template.format || :json
        content_type = Mime[format].to_s

        body = render(
          template: template.virtual_path,
          formats: format,
          **options,
        )
      rescue ActionView::MissingTemplate => error
        body = ""
        content_type = headers["Content-Type"]
      end

      payload = CGI.unescapeHTML(body).to_s

      app = Rails.configuration.action_client.request_middleware.build(
        proc do |env|
          request = ActionDispatch::Request.new(env)

          [200, request.headers, request.body]
        end
      )

      status, request_headers, body = app.call(
        Rack::RACK_URL_SCHEME => uri.scheme,
        Rack::HTTP_HOST => "#{uri.hostname}:#{uri.port}",
        Rack::REQUEST_METHOD => method.to_s.upcase,
        "ORIGINAL_FULLPATH" => uri.path,
        Rack::PATH_INFO => uri.path,
        Rack::RACK_INPUT => StringIO.new(payload),
      )

      action_dispatch_request = ActionDispatch::Request.new(
        request_headers.merge("RAW_POST_DATA" => Array(body).join),
      )

      headers.with_defaults(
        "Content-Type": content_type,
        "Accept": content_type,
      ).each do |key, value|
        action_dispatch_request.headers[key] = value
      end

      mod = Module.new do
        def submit
          app = Rails.configuration.action_client.response_middleware.build(
            ActionClient::Middleware::Net::HttpClient.new
          )

          app.call(env)
        end
      end

      action_dispatch_request.extend(mod)

      action_dispatch_request
    end

    %i(
      connect
      delete
      get
      head
      options
      patch
      post
      put
      trace
    ).each do |verb|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{verb}(**options)
          build_request(method: #{verb.inspect}, **options)
        end
      RUBY
    end
  end
end
