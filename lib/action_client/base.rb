 require_dependency "action_client/request"

module ActionClient
  class Base < AbstractController::Base
    abstract!

    include AbstractController::Rendering
    include ActionView::Layouts

    cattr_accessor :adapters,
      instance_accessor: true,
      default: ActiveSupport::OrderedOptions.new

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

    def build_request(method:, path:, locals: {})
      adapter = adapters.fetch(defaults.adapter)

      template_path = self.class.client_name
      template_name = action_name
      template = lookup_context.find(template_name, Array(template_path))
      format = template.format || :json

      uri = URI(File.join(URI(defaults.url).to_s, path.to_s))

      body = render(
        template: template.virtual_path,
        formats: format,
        locals: locals,
      )

      headers = defaults.headers.to_h.with_defaults(
        "Content-Type": Mime[format].to_s,
      ).merge(defaults.headers.to_h)

      request = ActionDispatch::Request.new({})
      request.request_method = method.to_s.upcase

      headers.each do |key, value|
        request.headers[key] = value
      end
      request.headers[Rack::RACK_URL_SCHEME] = uri.scheme
      request.headers[Rack::HTTP_HOST] = uri.hostname
      request.headers["ORIGINAL_FULLPATH"] = uri.path
      request.headers["RAW_POST_DATA"] = CGI.unescapeHTML(body)

      request
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
